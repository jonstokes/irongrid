require 'spec_helper'

describe LinkMessage do
  before :all do
    IRONGRID_REDIS_POOL.with { |conn| conn.flushdb }
  end

  before :each do
    @attrs = {
      url:             "http://www.retailer.com/1",
      page_attributes: { "digest" => "abc123", "title" => "Product 1"},
      page_is_valid:   true,
      page_not_found:  false
    }
    @db_attrs = { listing_id: 1, listing_digest: "124abc"}
  end

  describe "::new" do
    it "creates a new LinkMessage object from an opts hash" do
      ld = LinkMessage.new(@attrs)
      expect(ld).to be_a(LinkMessage)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.page_attributes.keys).to include("digest")
      expect(ld.page_is_valid).to be_true
    end

    it "creates a new LinkMessage object from a Listing object" do
      listing = FactoryGirl.create(:retail_listing)
      ld = LinkMessage.new(listing)
      expect(ld).to be_a(LinkMessage)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.listing_digest).to match(/digest\-\d/)
      expect(ld.listing_id).to be_a(Integer)
    end
  end

  describe "#update" do
    it "updates the link's data" do
      ld = LinkMessage.new(@attrs)
      ld.update(page_is_valid: false)
      expect(ld.page_is_valid?).to eq(false)
    end
  end


  describe "db attributes" do
    it "has db_digest and db_id attributes if the link is in the db" do
      pending "Example"
    end
  end

  describe "scraped attributes" do
    it "has digest and attributes" do
      pending "Example"
    end
  end

  describe "scraped status checks" do
    it "responds to not_found? and is_valid?" do
      pending "Example"
    end
  end
end
