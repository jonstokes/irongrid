require 'spec_helper'

describe SetPriceAttributes do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
    end

    it "correctly sets prices for a retail listing" do
      raw_listing = {
        "validation" => {
          "retail" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']",
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
        "sale_price" => "$600.00",
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "category1" => "Guns"
      }
      result = SetPriceAttributes.perform(
        site: @site,
        raw_listing: raw_listing,
        adapter: @site.page_adapter,
        type: "RetailListing"
      )
      expect(result.price_in_cents).to eq(65000)
      expect(result.sale_price_in_cents).to eq(60000)
    end


    it "correctly sets prices for a classified listing" do
      raw_listing = {
        "validation" => {
          "classified" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']",
        },
        "seller_defaults"=> {
          "condition"=>"new",
          "listing_type"=>"classified",
          "stock_status"=>"In Stock",
          "item_location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705"
        },
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price" => "$650.00",
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "category1" => "Guns"
      }
      result = SetPriceAttributes.perform(
        site: @site,
        raw_listing: raw_listing,
        adapter: @site.page_adapter,
        type: "ClassifiedListing"
      )
      expect(result.price_in_cents).to eq(65000)
    end

    it "correctly sets prices for an auction listing" do
      raw_listing = {
        "validation" => {
          "auction" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']"
        },
        "seller_defaults"=> {
          "condition"=>"new",
          "listing_type"=>"auction",
          "stock_status"=>"In Stock",
          "item_location"=>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705"
        },
        "title" => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords" => "CITADEL 1911 COMPACT .45ACP",
        "image" => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "current_bid" => "$1.00",
        "buy_now_price" => "$2.00",
        "minimum_bid" => "$3.00",
        "reserve" => "$4.00",
        "description" => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "category1" => "Guns"
      }
      result = SetPriceAttributes.perform(
        site: @site,
        raw_listing: raw_listing,
        adapter: @site.page_adapter,
        type: "ClassifiedListing"
      )
      expect(result.current_bid_in_cents).to eq(100)
      expect(result.buy_now_price_in_cents).to eq(200)
      expect(result.minimum_bid_in_cents).to eq(300)
      expect(result.reserve_in_cents).to eq(400)
    end

  end
end
