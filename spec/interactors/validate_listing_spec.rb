require 'spec_helper'

describe ValidateListing do
  before :each do
    @site = create_site "www.retailer.com"
    @raw_listing = {
      "validation" => {
        "retail" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']",
        "classified" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']",
        "auction" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']"
      },
      "seller_defaults"=> {
        "condition"=>"new",
        "listing_type"=>"retail",
        "stock_status"=>"In Stock",
        "item_location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705"
      },
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
    end

    it "fails a sold classified" do
      raw_listing = @raw_listing.merge("item_sold" => "yes")
      result = ValidateListing.perform(
        raw_listing: raw_listing,
        site: @site,
        type: "ClassifiedListing"
      )
      expect(result.success?).to be_false
    end

    it "fails an ended auction" do
      raw_listing = @raw_listing.merge("auction_ended" => "#{Time.now - 1.day}")
      result = ValidateListing.perform(
        raw_listing: raw_listing,
        site: @site,
        type: "AuctionListing"
      )
      expect(result.success?).to be_false
    end
  end
end
