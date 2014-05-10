require 'spec_helper'

describe SetCommonAttributes do
  describe "#perform" do
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

    it "correctly sets common attributes" do
      result = SetCommonAttributes.perform(
        site: @site,
        raw_listing: @raw_listing,
        adapter: @site.page_adapter
      )

      expect(result.title.raw).to eq(@raw_listing['title'])
      expect(result.keywords.raw).to eq(@raw_listing['keywords'])
      expect(result.category1.raw).to eq(@raw_listing['category1'])
      expect(result.description).to eq(@raw_listing['description'])
      expect(result.image_source).to eq(@raw_listing['image'])
      expect(result.item_condition).to eq(@raw_listing['seller_defaults']['item_condition'])
      expect(result.item_location).to eq(@raw_listing['seller_defaults']['item_location'])
    end
  end
end
