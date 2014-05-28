require 'spec_helper'
require 'mocktra'

describe ExtractRawListingFromPage do
  before :each do
    @http = PageUtils::HTTP.new
  end

  describe "#perform" do
    before :each do
      @site = create_site("www.retailer.com")
      Mocktra(@site.domain) do
        get '/1.html' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/1.html") do |file|
            file.read
          end
        end
      end
      @raw_listing_hash = {
        "validation" => {
          "retail" => "(raw['price'] || raw['sale_price']) && raw['title'] && raw['image'] && raw['description']"
        },
        "seller_defaults"=> {
          "item_condition"=>"new",
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

    it "correctly extracts a raw_listing hash from a page object" do
      url = "http://www.retailer.com/1.html"
      page = @http.fetch_page(url)
      doc = DocReader.new(url: url, doc: page.doc)
      opts = {
        site: @site,
        adapter_type: :page,
        page: page,
        doc: doc,
        url: url,
      }
      result = ExtractRawListingFromPage.perform(opts)
      expect(result.raw_listing).to eq(@raw_listing_hash)
    end

  end
end

