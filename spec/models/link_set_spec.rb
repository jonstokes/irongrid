require 'spec_helper'

describe LinkSet do

  before :all do
    @store = LinkSet.new(namespace: "rspec-linkset", domain: "www.rspec.com")
  end

  before :each do
    @links = [
      { url: "http://www.rspec.com/1" },
      { url: "http://www.rspec.com/2" },
      { url: "http://www.rspec.com/3" }
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
      link = { url: "http://www.rspec.com/1" }
      @store.add(link)
      @store.size.should == 1
    end

    it "adds links with database ids" do
      links = [
        { url: "http://www.rspec.com/1", id: 1 },
        { url: "http://www.rspec.com/2", id: 2 },
        { url: "http://www.rspec.com/3", id: 3 }
      ]
      @store.add(links)
      @store.size.should == 3
      link = @store.pop
      link[:url].should_not be_nil
      link[:id].should be_a(Integer)
    end

    it "adds a single link with a database id" do
      link = { url: "http://www.rspec.com/1", id: 1  }
      @store.add(link)
      @store.size.should == 1
      link = @store.pop
      link[:url].should_not be_nil
      link[:id].should be_a(Integer)
    end

    it "does not add a key twice" do
      link = { url: "http://www.rspec.com/1" }
      @store.add(link)
      @store.add(link)
      @store.size.should == 1
    end

    it "does not add a key twice, but will add a database id for an existing key that didn't have one" do
      link = { url: "http://www.rspec.com/1" }
      link2 = { url: "http://www.rspec.com/1", id: 1 }
      @store.add(link)
      @store.add(link2)
      @store.size.should == 1
      @store.pop.should == { url: "http://www.rspec.com/1", id: 1 }
    end

    it "should not allow the same key to be added twice in the same array" do
      links = @links + [{ url: "http://www.rspec.com/1" }]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "will not add a link from a different domain" do
      links = [
        { url: "http://www.rspec.com/1" },
        { url: "http://www.rspec.com/2" },
        { url: "http://www.foo.com/3" }
      ]
      @store.add(links).should == 2
      @store.size.should == 2
    end

    it "should add a previously popped link" do
      @store.add(@links).should == 3
      link = @store.pop
      @store.add(link).should == 1
      @store.size.should == 3
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      @store.add(@links).should == 3
      @store.size.should == 3
      @store.clear
      @store.should be_empty
    end
  end

  describe "#size", no_es: true do
    it "should count the items in the store" do
      @store.add(@links).should == 3
      @store.size.should == 3
    end
  end

  describe "#pop", no_es: true do
    it "should return a link and remove it from the queue" do
      @store.add(@links)
      link = @store.pop
      link.should_not be_nil
      @store.has_key?(link).should be_false
    end
  end
end
