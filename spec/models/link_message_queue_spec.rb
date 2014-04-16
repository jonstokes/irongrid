require 'spec_helper'

describe LinkMessageQueue do

  before :all do
    @store = LinkMessageQueue.new(domain: "www.retailer.com")
  end

  before :each do
    @links = (1..3).map { |i| LinkMessage.new(url: "http://www.retailer.com/#{i}") }
  end

  after :each do
    @store.clear
  end

  describe "#add", no_es: true do

    it "adds a batch of links" do
      @store.add(@links).should == 3
      expect(@store.size).to eq(3)
    end

    it "adds a single key" do
      expect(@store.add(@links.first)).to be_true
      expect(@store.size).to eq(1)
    end

    it "does not add a key twice" do
      @store.add(@links.first)
      expect(@store.add(@links.first)).to be_zero
      expect(@store.size).to eq(1)
    end

    it "should not allow the same key to be added twice in the same array" do
      links = @links + [ @links.first ]
      @store.add(links).should == 3
      @store.size.should == 3
    end

    it "will not add a link from a different domain" do
      @links << LinkMessage.new(url: "http://www.foo.com/")
      @store.add(@links).should == 3
      @store.size.should == 3
    end

    it "should add a previously popped link" do
      expect(@store.add(@links)).to eq(3)
      link = @store.pop
      expect(@store.add(link)).to be_true
      expect(@store.size).to eq(3)
    end
  end

  describe "#rem" do
    it "removes a link" do
      @store.add(@links).should == 3
      @store.rem(@links.first.url)
      expect(@store.has_key?(@links.first.url)).to be_false
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
      @store.add(@links.first.dup.update(page_attributes: {'foo' => 1, 'bar' => 2}))
      link = @store.pop
      expect(link).not_to be_nil
      expect(@store.has_key?(link.url)).to be_false
      expect(link).to be_a(LinkMessage)
      expect(link.url['http']).not_to be_nil
      expect(link.page_attributes).to eq({'foo' => 1, 'bar' => 2})
    end
  end
end
