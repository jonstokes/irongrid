require 'spec_helper'

def visible_messages(threshold)
  return @sqs_queue.visible_messages if threshold == 0
  count = 0
  i = 10
  begin
   count = @sqs_queue.visible_messages
  end until (count >= threshold) || (i -= 1).zero?
  raise "Visibility check timed out" if i == 0
  count
end

def invisible_messages(threshold)
  return @sqs_queue.invisible_messages if threshold == 0
  count = 0
  i = 10
  begin
   count = @sqs_queue.invisible_messages
  end until (count >= threshold) || (i -= 1).zero?
  raise "Visibility check timed out" if i == 0
  count
end

describe SuperQueue do

  before :all do
    @sqs = AWS::SQS.new(AWS_CREDENTIALS)
    @sqs_queue = @sqs.queues.named("queue-scoperrific-rspec")
    @s3 = AWS::S3.new(AWS_CREDENTIALS)
    @bucket = @s3.buckets["scoperrific-rspec"]
  end

  after :all do
    queue = SuperQueue.new(:name => "scoperrific-rspec")
    queue.clear
    queue.shutdown
  end

  before :each do
    @defaults = {
      :name => "scoperrific-rspec",
      :bucket_name => "scoperrific-rspec",
    }
  end

  after :each do
    puts "## Invisible: #{invisible_messages(0)}"
  end

  describe "#new" do
    it "requires non-nil options" do
      expect {
        SuperQueue.new(nil)
      }.to raise_error(RuntimeError, "Options can't be nil!")
    end

    describe "with standard defaults" do
      before :each do
        @queue = SuperQueue.new(@defaults)
      end

      it "should create a new SuperQueue" do
        @queue.should be_an_instance_of SuperQueue
      end

      it "should create a new SuperQueue with a url" do
        @queue.url.should include("http")
      end

      it "should not use s3 if s3 is disabled" do
        SuperQueue.new(@defaults.merge(:disable_s3 => true)).use_s3?.should == false
      end
    end

    describe "with missing or incorrect defaults" do
      it "requires that visibility timeout be an integer" do
        @defaults.merge!(:visibility_timeout => "a")
        expect {
          SuperQueue.new(@defaults)
        }.to raise_error(RuntimeError, "Visbility timeout must be an integer (in seconds)!")
      end
    end

    describe "with optional options" do
      it "should use a supplied name" do
        @defaults.merge!(:name => "rspec-test")
        @queue = SuperQueue.new(@defaults)
        @queue.url.should include(@defaults[:name])
        @queue.name.should include(@defaults[:name])
        @queue.clear
        @queue.shutdown
      end
    end
  end

  describe "#push" do
    before(:each) do
      @q = SuperQueue.new(@defaults)
      @q.clear
    end

    after(:each) do
      @q.clear
      @q.shutdown
    end

    it "should add an element" do
      @q.push(:url => "http://bar.com/", :html => "foo")
      @q.length.should == 1
    end

    it "should send the buffer overflow to SQS" do
      20.times do |i|
        @q << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      @q.send(:clear_in_buffer)
      sleep 2
      visible_messages(1).should_not == 0
    end

    it "should send large objects to S3" do
      html =  "<html><body>#{Faker::Lorem.paragraph(5000)}</body></html>"
      html.size.should > 64000
      20.times do |i|
        @q << { :url => "http://foo.com/", :html => html }
      end
      @q.send(:clear_in_buffer)
      m = @q.pop
      #puts "Popped: #{@q.pop} | #{@q.pop}"
      m[:html].should == html
      @bucket.should_not be_empty
    end

    it "should not use s3 if s3 is disabled" do
      @bucket.objects.each { |o| o.delete }
      queue = SuperQueue.new(@defaults.merge(disable_s3: true))
      queue.clear
      10.times do |i|
        queue << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      queue.send(:clear_in_buffer)
      visible_messages(5).should > 5
      @bucket.should be_empty
      queue.clear
      queue.shutdown
    end
  end

  describe "#pop" do
    before(:each) do
      @q = SuperQueue.new(@defaults)
      @q.clear
    end

    after(:each) do
      @q.clear
      @q.shutdown
    end

    it "reads an element from SQS" do
      20.times do |i|
        @q << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      @q.send(:clear_in_buffer)
      sleep 2 # to let item propagate from in_buffer to SQS @q
      page = @q.pop
      page.should_not be_nil
      page[:url].should_not be_nil
      page[:html].should_not be_nil
    end

    it "deletes popped messages from the queue every ten pops" do
      20.times do |i|
        @q << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      @q.send(:clear_in_buffer)
      sleep 2 # to let item propagate from in_buffer to SQS queue
      5.times { @q.pop }
      visible_messages(5).should > 5
      invisible = invisible_messages(1)
      invisible.should > 1

      @q.clear
      invisible_messages(0).should < invisible
    end

    it "should properly return large objects that have been encoded" do
      text = Faker::Lorem.paragraph(1600)
      20.times do |i|
        @q << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{text}</body></html>" }
      end
      @q.send(:clear_in_buffer)
      page = @q.pop
      page.should_not be_nil
      page.should be_a(Hash)
      page[:url].should include("http")
      page[:html].should be_a(String)
    end

    it "should clear the queue of pointers for objects that have been stored on S3 where objects were deleted from S3" do
      text = Faker::Lorem.paragraph(1600)
      20.times do |i|
        @q << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{text}</body></html>" }
      end
      @q.send(:clear_in_buffer)
      @bucket.objects.each { |o| o.delete }
      @q.pop.should be_nil
    end
  end

  describe "#clear" do
    it "should clear the queue" do
      queue = SuperQueue.new(@defaults)
      2.times do |i|
        queue << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      sleep 0.5 # to let items propagate from in_buffer to SQS queue
      queue.clear
      queue.should be_empty
      queue.shutdown
    end
  end

  describe "#length" do
    it "should give the length of the queue" do
      queue = SuperQueue.new(@defaults)
      queue.clear
      2.times do |i|
        queue << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      sleep 0.5 # to let items propagate from in_buffer to SQS queue
      queue.length.should == 2
      queue.clear
      queue.shutdown
    end
  end

  describe "#empty?" do
    it "should should return true if the queue is empty" do
      queue = SuperQueue.new(@defaults)
      queue.clear
      queue.should be_empty
    end

    it "should should return false if the queue is not empty" do
      queue = SuperQueue.new(@defaults)
      2.times do |i|
        queue << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      sleep 0.5 # to let items propagate from in_buffer to SQS queue
      queue.should_not be_empty
    end
  end

  describe "#shutdown" do
    it "should not blow up" do
      queue = SuperQueue.new(@defaults)
      expect { queue.shutdown }.not_to raise_error
    end
  end

  describe "#sqs_requests" do
    it "should keep track of the number of SQS requests" do
      queue = SuperQueue.new(@defaults)
      10.times do |i|
        queue << { :url => "http://foo.com/#{i}", :html => "<html><body>#{i} #{Faker::Lorem.paragraph}</body></html>" }
      end
      queue.send(:clear_in_buffer)
      9.times { queue.pop }
      queue.length
      queue.sqs_requests.should_not == 0
      queue.clear
      queue.shutdown
    end
  end
end
