require 'spec_helper'

describe CopyAttributes do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
      @url = "http://#{@site.domain}/product/1"
      @listing_json = Hashie::Mash.new(
          "url" => @url,
          "condition"=>"new",
          "type"=>"retail",
          "availability"=>"in_stock",
          "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
          "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
          "price_in_cents" => 65000,
          "sale_price_in_cents" => 60000,
          "current_price_in_cents" => 60000,
          'shipping_cost_in_cents' => 200,
          "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS"
      )
      @listing = IronBase::Listing.new(
          type: 'RetailListing',
          url: { page: 'http://www.retailer.com/1' }
      )
    end

    it "correctly copies attribues for a listing" do
      listing = CopyAttributes.call(
        site: @site,
        listing_json: @listing_json,
        type: "RetailListing"
      ).listing

      expect(listing.url.page).to eq(@url)
      expect(listing.condition).to eq("new")
      expect(listing.location.source).to eq("1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705")
      expect(listing.type).to eq("retail")
      expect(listing.availability).to eq("in_stock")
      expect(listing.price.list).to eq(65000)
      expect(listing.price.sale).to eq(60000)
      expect(listing.shipping_cost).to eq(200)
    end
  end

  it "correctly sets seller attributes for a retail listing" do
    result = DeriveAttributes.call(
        site:         @site,
        listing:      @listing,
        listing_json: @listing_json,
    )

    expect(result.listing.seller.domain).to eq(@site.domain)
    expect(result.listing.seller.site_name).to eq(@site.name)
  end


  it "correctly sets common attributes for an auction listing" do
    listing = @listing.merge(type: 'AuctionListing', auction_ends: "09/10/2025")
    result = DeriveAttributes.call(
        site:         @site,
        listing:      listing,
        listing_json: @listing_json
    )
    expect(result.listing.auction_ends.to_s).to eq("2025-09-10 05:00:00 UTC")
  end

end
