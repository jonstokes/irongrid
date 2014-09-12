require 'spec_helper'

describe CopyAttributes do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
      @url = "http://#{@site.domain}/product/1"
    end

    it "correctly copies attribues for a listing" do
      listing_json = Hashie::Mash.new(
        "url" => @url,
        "condition"=>"new",
        "type"=>"retail",
        "availability"=>"in_stock",
        "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price_in_cents" => 65000,
        "sale_price_in_cents" => 60000,
        "current_price_in_cents" => 60000,
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS"
      )
      result = CopyAttributes.perform(
        site: @site,
        listing_json: listing_json,
        type: "RetailListing"
      )
      expect(result.url).to eq(@url)
      expect(result.item_condition).to eq("new")
      expect(result.item_location).to eq("1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705")
      expect(result.type).to eq("retail")
      expect(result.availability).to eq("in_stock")
      expect(result.price_in_cents).to eq(65000)
      expect(result.sale_price_in_cents).to eq(60000)
    end
  end
end
