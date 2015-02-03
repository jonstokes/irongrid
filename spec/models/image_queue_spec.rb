require 'spec_helper'

describe ImageQueue do

  before :all do
    @store = ImageQueue.new(domain: "www.rspec.com")
  end

  before :each do
    @links = [
       "http://www.rspec.com/1",
       "http://www.rspec.com/2",
       "http://www.rspec.com/3"
    ]
  end

  after :each do
    @store.clear
  end

  describe "#add", no_es: true do

    it "adds a batch of links" do
      @store.add(@links).should == 3
      @store.size.should == 3
    end

    it "adds a single key" do
      link =  "http://www.rspec.com/1"
      expect(@store.add(link)).to eq(true)
      @store.size.should == 1
    end

    it "does not add a key twice" do
      link =  "http://www.rspec.com/1"
      @store.add(link)
      expect(@store.add(link)).to eq(false)
      expect(@store.size).to eq(1)
    end

    it "should not allow the same key to be added twice in the same array" do
      links = @links + [ "http://www.rspec.com/1"]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "will not add a link from a different domain" do
      links = [
         "http://www.rspec.com/1",
         "http://www.rspec.com/2",
        { url: "http://www.foo.com/3" }
      ]
      @store.add(links).should == 2
      @store.size.should == 2
    end

    it "should add a previously popped link" do
      expect(@store.add(@links)).to eq(3)
      link = @store.pop
      expect(@store.add(link)).to eq(true)
      expect(@store.size).to eq(3)
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      links = ["http://www.rspec.com/1", "http://www.rspec.com/2", "http://www.rspec.com/3"]
      @store.add(links).should == 3
      @store.size.should == 3
      @store.clear
      @store.should be_empty
    end
  end

  describe "#size", no_es: true do
    it "should count the items in the store" do
      links = ["http://www.rspec.com/1", "http://www.rspec.com/2", "http://www.rspec.com/"]
      @store.add(links).should == 3
      @store.size.should == 3
    end
  end

  describe "#pop", no_es: true do
    it "should return a link and remove it from the queue" do
      links = %w(http://www.rspec.com/1 http://www.rspec.com/2 http://www.rspec.com/3 http://www.rspec.com/4 http://www.rspec.com/5) 
      @store.add(links)
      link = @store.pop
      link.should_not be_nil
      @store.has_key?(link).should eq(false)
    end
  end
end

