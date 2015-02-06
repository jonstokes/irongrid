require 'spec_helper'

describe IronCore::LinkMessage do
  before :each do
    @attrs = {
      url:             "http://www.retailer.com/1",
      page_attributes: { "digest" => "abc123", "title" => "Product 1"},
      page_is_valid:   true,
      page_not_found:  false
    }
  end

  describe "::new" do
    it "creates a new LinkMessage object from an opts hash" do
      msg = IronCore::LinkMessage.new(@attrs)
      expect(msg).to be_a(IronCore::LinkMessage)
      expect(msg.url).to match(/www\.retailer\.com\/\d/)
      expect(msg.page_attributes.keys).to include("digest")
      expect(msg.page_is_valid).to eq(true)
    end

    it "creates a new LinkMessage object from a Listing object" do
      listing = FactoryGirl.create(:listing)
      msg = IronCore::LinkMessage.new(listing)
      expect(msg).to be_a(IronCore::LinkMessage)
      expect(msg.url).to match(/www\.retailer\.com\/\d/)
      expect(msg.listing_digest).to eq(listing.digest)
      expect(msg.current_listing_id).to eq(listing.id)
    end
  end

  describe "#update" do
    it "updates the link's data" do
      msg = IronCore::LinkMessage.new(@attrs)
      msg.update(page_is_valid: false)
      expect(msg.page_is_valid?).to eq(false)
    end
  end


  describe "db attributes" do
    it "has db_digest and db_id attributes if the link is in the db" do
      pending "Example"
      expect(true).to eq(false)
    end
  end

  describe "scraped attributes" do
    it "has digest and attributes" do
      pending "Example"
      expect(true).to eq(false)
    end
  end

  describe "scraped status checks" do
    it "responds to not_found? and is_valid?" do
      pending "Example"
      expect(true).to eq(false)
    end
  end
end
