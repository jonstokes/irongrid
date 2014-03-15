require 'spec_helper'

describe ListingSet do

  before :all do
    @store = ListingSet.new
  end

  after :each do
    @store.clear
  end

  describe "#add", no_es: true do

    it "should add a batch of listings" do
      listings = [{id: 1, status: "delete"}, {id: 2, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.add(listings).should == 3
      @store.size.should == 3
    end

    it "should add a single listing" do
      listing = {id: 1, status: "delete"}
      @store.add(listing).should == 1
      @store.size.should == 1
    end

    it "does not add the same listing twice" do
      listing = {id: 1, status: "delete"}
      @store.add(listing).should == 1
      @store.add(listing)
      @store.size.should == 1
    end

    it "should not allow the same key to be added twice in the same array" do
      listings = [{id: 1, status: "delete"}, {id: 1, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.add(listings).should == 2
      @store.size.should == 2
    end

    it "should add a previously popped listing" do
      listings = [{id: 1, status: "delete"}, {id: 2, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.add(listings).should == 3
      listing = @store.pop
      @store.add([listing])
      @store.size.should == 3
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      listings = [{id: 1, status: "delete"}, {id: 2, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.clear
      @store.should be_empty
    end
  end

  describe "#size", no_es: true do
    it "should count the items in the store" do
      listings = [{id: 1, status: "delete"}, {id: 2, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.add(listings).should == 3
      @store.size.should == 3
    end
  end

  describe "#pop", no_es: true do
    it "should return a listing and remove it from the queue" do
      listings = [{id: 1, status: "delete"}, {id: 2, status: "delete"}, {id: 3, status: "deactivate"}]
      @store.add(listings)
      listing = @store.pop
      listing.should_not be_nil
      @store.has_key?(listing).should be_false
      listing.should be_a(Hash)
      listing[:id].should_not be_nil
    end
  end
end
