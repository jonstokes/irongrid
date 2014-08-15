require 'spec_helper'

describe Stretched::ObjectQueue do

  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    @store = Stretched::ObjectQueue.find_or_create("www.retailer.com")
    @objects = (1..3).map do |i|
      {
        url: "http://www.retailer.com/#{i}"
      }
    end
  end

  describe "#add", no_es: true do

    it "adds a batch of objects" do
      @store.add(@objects).should == 3
      expect(@store.size).to eq(3)
    end

    it "adds a single object" do
      expect(@store.add(@objects.first)).to be_true
      expect(@store.size).to eq(1)
    end

    it "does not add an object twice" do
      @store.add(@objects.first)
      expect(@store.add(@objects.first)).to be_zero
      expect(@store.size).to eq(1)
    end

    it "should add a previously popped object" do
      expect(@store.add(@objects)).to eq(3)
      object = @store.pop
      expect(@store.add(object)).to be_true
      expect(@store.size).to eq(3)
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      @store.add(@objects).should == 3
      @store.size.should == 3
      @store.clear
      @store.should be_empty
    end
  end


  describe "#pop", no_es: true do
    it "should return an object and remove it from the queue" do
      @store.add(@objects.first.dup.update(page_attributes: {'foo' => 1, 'bar' => 2}))
      object = @store.pop
      key = Stretched::ObjectQueue.key(object)

      expect(object).not_to be_nil
      expect(@store.has_key?(key)).to be_false
      expect(Stretched::ObjectQueue.get(key)).to be_nil
      expect(object).to be_a(Hashie::Mash)
      expect(object.http).not_to be_nil
      expect(object.page_attributes).to eq({'foo' => 1, 'bar' => 2})
    end

    it "returns nil if the queue is empty" do
      expect(@store.pop).to be_nil
    end
  end
end
