require 'spec_helper'

describe SetPriceAttributes do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
    end

    it "correctly sets prices for a retail listing" do
      listing_json = Hashie::Mash.new(
        "condition"=>"new",
        "type"=>"retail",
        "availability"=>"in_stock",
        "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price_in_cents" => 65000,
        "sale_price_in_cents" => 60000,
        "current_price_in_cents" => 60000,
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "product_category1" => "Guns"
      )
      result = SetPriceAttributes.perform(
        site: @site,
        listing_json: listing_json,
        type: "RetailListing"
      )
      expect(result.price_in_cents).to eq(65000)
      expect(result.sale_price_in_cents).to eq(60000)
      expect(result.current_price_in_cents_with_shipping).to eq(60000)
    end

    it "correctly sets prices for a retail listing with shipping" do
      listing_json = Hashie::Mash.new(
        "condition"=>"new",
        "type"=>"retail",
        "availability"=>"in_stock",
        "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price_in_cents" => 65000,
        "sale_price_in_cents" => 60000,
        "current_price_in_cents" => 60000,
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "product_category1" => "Guns"
      )
      result = SetPriceAttributes.perform(
        site: @site,
        listing_json: listing_json,
        type: "RetailListing",
        shipping_cost_in_cents: 10
      )
      expect(result.price_in_cents).to eq(65000)
      expect(result.sale_price_in_cents).to eq(60000)
      expect(result.current_price_in_cents_with_shipping).to eq(60010)
    end

    it "correctly sets prices for a classified listing" do
      listing_json = Hashie::Mash.new(
        "condition"=>"new",
        "type"=>"classified",
        "availability"=>"in_stock",
        "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK",
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price_in_cents" => 65000,
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "product_category1" => "Guns"
      )
      result = SetPriceAttributes.perform(
        site: @site,
        listing_json: listing_json,
        type: "ClassifiedListing"
      )
      expect(result.price_in_cents).to eq(65000)
    end

    it "correctly sets prices for an auction listing" do
      listing_json = Hashie::Mash.new(
        "condition"=>"new",
        "type"=>"auction",
        "availability"=>"in_stock",
        "location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "current_bid_in_cents" => 100,
        "buy_now_price_in_cents" => 200,
        "minimum_bid_in_cents" => 300,
        "reserve_in_cents" => 400,
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "product_category1" => "Guns"
      )
      result = SetPriceAttributes.perform(
        site: @site,
        listing_json: listing_json,
        type: "ClassifiedListing"
      )
      expect(result.current_bid_in_cents).to eq(100)
      expect(result.buy_now_price_in_cents).to eq(200)
      expect(result.minimum_bid_in_cents).to eq(300)
      expect(result.reserve_in_cents).to eq(400)
    end

  end
end
