require 'spec_helper'

describe LinkSet do

  before :all do
    @store = LinkSet.new(namespace: "rspec-linkset", domain: "www.rspec.com")
  end

  after :each do
    @store.clear
  end

  describe "#add", no_es: true do

    it "should add a batch of keys" do
      links = ["http://www.rspec.com/1", "http://www.rspec.com/2", "http://www.rspec.com/3"]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "should add a single key" do
      link = "http://www.rspec.com/1"
      @store.add(link)
      @store.size.should == 1
    end

    it "does not add a key twice" do
      link = "http://www.rspec.com/1"
      @store.add(link)
      @store.add(link)
      @store.size.should == 1
    end

    it "should not allow the same key to be added twice in the same array" do
      links = ["http://www.rspec.com/1", "http://www.rspec.com/1", "http://www.rspec.com/3", "http://www.rspec.com/4"]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "will not add a link from a different domain" do
      links = ["http://www.foo.com/1", "http://www.rspec.com/2", "http://www.rspec.com/3", "http://www.rspec.com/4"]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "should add a previously popped link" do
      links = ["http://www.rspec.com/1", "http://www.rspec.com/2", "http://www.rspec.com/3"]
      @store.add(links).should == 3
      link = @store.pop
      links2 = ["http://www.rspec.com/4", link]
      @store.add(links2).should == 2
      @store.size.should == 4
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
      @store.has_key?(link).should be_false
    end
  end
end
