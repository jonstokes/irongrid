require 'spec_helper'

describe DeriveAttributes do
  describe "#perform" do
    before :each do
      @site = create_site "www.retailer.com"
      @listing_json = Hashie::Mash.new(
        "valid"               => true,
        "condition"           =>"new",
        "type"                =>"RetailListing",
        "availability"        =>"in_stock",
        "location"            =>"1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705",
        "title"               => "CITADEL 1911 COMPACT .45ACP 3 1/2\" HOGUE BLACK", 
        "keywords"            => "CITADEL 1911 COMPACT .45ACP",
        "image"               => "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG",
        "price_in_cents"      => "65000",
        "sale_price_in_cents" => "65000",
        "description"         => ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS",
        "product_category1"   => "Guns",
        "product_sku"         => "1911-CIT45CSPHB"
      )
    end

    it "correctly sets affiliate_program attribute for an affiliate" do
      site = create_site "www.botach.com"
      result = DeriveAttributes.perform(
        type: @listing_json['type'],
        site: site,
        listing_json: @listing_json,
      )
      expect(result.affiliate_program).to eq("ShareASale")
    end

    it "correctly sets common attributes for a retail listing" do
      result = DeriveAttributes.perform(
        type: @listing_json['type'],
        site: @site,
        listing_json: @listing_json,
      )

      expect(result.title.raw).to eq(@listing_json['title'])
      expect(result.category1.raw).to eq(@listing_json['product_category1'])
      expect(result.category1.classification_type).to eq("hard")
      expect(result.seller_domain).to eq(@site.domain)
      expect(result.seller_name).to eq(@site.name)
      expect(result.affiliate_link_tag).to be_nil
    end

    it "adds an affiliate link tag if the site has one" do
      site = Site.new(domain: "www.luckygunner.com", source: :fixture)
      site.send(:write_to_redis)

      url = "http://www.luckygunner.com/product1"
      listing_json = Hashie::Mash.new(
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => url,
        "product_category1" => "Ammunition"
      )
      result = DeriveAttributes.perform(
        type: @listing_json['type'],
        site: site,
        listing_json: listing_json,
      )
      expect(result.affiliate_link_tag).to eq("#rid=ironsights&amp;chan=search")
    end

    it "correctly sets common attributes for an auction listing" do
      @listing_json['type'] = "AuctionListing"
      @listing_json.auction_ends = "09/10/2025"
      result = DeriveAttributes.perform(
        type: @listing_json['type'],
        site: @site,
        listing_json: @listing_json,
      )
      expect(result.auction_ends.to_s).to eq("2025-09-10 05:00:00 UTC")
    end
  end
end
