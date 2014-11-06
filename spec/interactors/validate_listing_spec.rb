require 'spec_helper'

describe ValidateListing do
  before :each do
    @site = create_site "www.retailer.com"
    @listing_json = Hashie::Mash.new(
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
    )
  end

  describe "#call" do
    it "passes a valid listing" do
      result = ValidateListing.call(
        listing_json: @listing_json,
        site: @site,
        listing: IronBase::Listing.new(auction_ends: Time.now + 5.days)
      )
      expect(result.success?).to be_true
    end

    it "fails an invalid listing" do
      result = ValidateListing.call(
        listing_json: @listing_json.merge(valid: false),
        site: @site,
        listing: IronBase::Listing.new(auction_ends: Time.now + 5.days)
      )
      expect(result.success?).to be_false
      expect(result.status).to eq(:invalid)
    end

    it "fails an ended auction" do
      result = ValidateListing.call(
        listing_json: @listing_json.merge(type: 'AuctionListing'),
        site: @site,
        listing: IronBase::Listing.new(
            type: 'AuctionListing',
            auction_ends: Time.now - 1.day
        )
      )

      expect(result.success?).to be_false
      expect(result.status).to eq(:not_found)
    end
  end
end
