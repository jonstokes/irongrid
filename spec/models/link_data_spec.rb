require 'spec_helper'

describe LinkData do
  before :all do
    IRONGRID_REDIS_POOL.with { |conn| conn.flushdb }
  end

  before :each do
    LinkData.delete_all
    @attrs = {
      url:             "http://www.retailer.com/1",
      page_attributes: { "digest" => "abc123", "title" => "Product 1"},
      page_is_valid:   true,
      page_not_found:  false
    }
    @db_attrs = { listing_id: 1, listing_digest: "124abc"}
  end

  describe "::new" do
    it "creates a new LinkData object from an opts hash, but does not add anything to redis" do
      ld = LinkData.new(@attrs)
      expect(ld).to be_a(LinkData)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.page_attributes.keys).to include("digest")
      expect(ld.page_is_valid).to be_true
      expect(LinkData.find(ld.url)).to be_nil
    end

    it "creates a new LinkData object from a Listing object, but does not add anything to redis" do
      listing = FactoryGirl.create(:retail_listing)
      ld = LinkData.new(listing)
      expect(ld).to be_a(LinkData)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.listing_digest).to match(/digest\-\d/)
      expect(ld.listing_id).to be_a(Integer)
      expect(LinkData.find(ld.url)).to be_nil
    end
  end

  describe "::create" do
    it "creates a new LinkData object from an opts hash, and adds it to redis" do
      ld = LinkData.create(@attrs)
      expect(ld).to be_a(LinkData)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.page_attributes.keys).to include("digest")
      expect(ld.page_is_valid).to be_true
      expect(LinkData.find(ld.url)).not_to be_nil
    end

    it "creates a new LinkData object from a Listing, and adds it to redis" do
      listing = FactoryGirl.create(:retail_listing)
      ld = LinkData.create(listing)
      expect(ld).to be_a(LinkData)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.listing_digest).to match(/digest\-\d/)
      expect(ld.listing_id).to be_a(Integer)
      expect(LinkData.find(ld.url)).not_to be_nil
    end

    it "does not create a new LinkData object in redis if that url already exists" do
      listing = FactoryGirl.create(:retail_listing)
      LinkData.create(listing)
      expect(LinkData.create(listing)).to be_nil
      expect(LinkData.size).to eq(1)
    end
  end

  describe "::find" do
    it "finds a link in redis by url, and returns a LinkData object" do
      listing = FactoryGirl.create(:retail_listing)
      LinkData.create(listing)
      ld = LinkData.find(listing.url)
      expect(ld).to be_a(LinkData)
      expect(ld.url).to match(/www\.retailer\.com\/\d/)
      expect(ld.listing_digest).to match(/digest\-\d/)
      expect(ld.listing_id).to be_a(Integer)
    end
  end

  describe "#update" do
    it "updates the link's data in redis" do
      ld = LinkData.create(@attrs)
      ld.update(page_is_valid: false)
      nld = LinkData.find(ld.url)
      expect(ld.page_is_valid?).to eq(false)
      expect(nld.page_is_valid?).to eq(false)
    end
  end

  describe "#destroy" do
    it "deletes the LinkData object from redis" do
      ld = LinkData.create(@attrs)
      ld.destroy
      IRONGRID_REDIS_POOL.with do |conn|
        expect(conn.get(ld.url)).to be_nil
        expect(conn.scard(LinkData::LINK_DATA_INDEX)).to be_zero
      end
    end
  end

  describe "db attributes" do
    it "has db_digest and db_id attributes if the link is in the db" do
      pending "Example"
    end
  end

  describe "db_dupe?" do
    it "is true if the scraped page is a new dupe" do
      # if digest != db_digest && (Listing.find("digest = ? && id != ?", digest, db_id))
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
