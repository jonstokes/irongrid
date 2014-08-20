require 'spec_helper'

describe ValidateListing do
  before :each do
    @site = create_site "www.retailer.com"
    @listing_json = {
      "valid" => true,
      "condition"=>"new",
      "type"=>"RetailListing",
      "availability"=>"in_stock",
      "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
      "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
      "keywords" => "CITADEL 1911 COMPACT .45ACP",
      "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
      "price" => "$650.00",
      "sale_price" => "$650.00",
      "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
      "category1" => "Guns"
    }
  end

  describe "#perform" do
    it "passes a valid listing" do
      result = ValidateListing.perform(
        raw_listing: @raw_listing,
        site: @site,
        type: "RetailListing"
      )
      expect(result.success?).to be_true
    end

    it "fails an invalid listing" do
      raw_listing = @raw_listing.merge("title" => nil)
      result = ValidateListing.perform(
        raw_listing: raw_listing,
        site: @site,
        type: "RetailListing"
      )
      expect(result.success?).to be_false
      expect(result.status).to eq(:invalid)
    end

    it "fails a not_found listing" do
      raw_listing = @raw_listing.merge("not_found" => true)
      result = ValidateListing.perform(
        raw_listing: raw_listing,
        site: @site,
        type: "ClassifiedListing"
      )
      expect(result.success?).to be_false
      expect(result.status).to eq(:not_found)
    end

    it "fails an ended auction" do
      raw_listing = @raw_listing.merge("auction_ended" => "#{Time.now - 1.day}")
      result = ValidateListing.perform(
        raw_listing: raw_listing,
        site: @site,
        type: "AuctionListing"
      )
      expect(result.success?).to be_false
      expect(result.status).to eq(:auction_ended)
    end
  end
end
