require 'spec_helper'

describe DeriveAttributes do
  describe "#call" do
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
      @listing = IronBase::Listing.new(
          type: 'RetailListing',
          url: { page: 'http://www.retailer.com/1' }
      )
    end

    describe '#purchase_url' do
      it 'returns the untagged url for a site without a link tag' do
        result = DeriveAttributes.call(
            site:         @site,
            listing:      @listing,
            listing_json: @listing_json,
        )
        expect(result.listing.url.purchase).to eq(@listing.url.page)
      end

      it 'returns an affiliate url for ShareASale site' do
        site = create_site 'www.botach.com'
        url = 'http://www.botach.com/fnh-scar-17s-7-62mm-battle-rifles-tan/'
        sas_link = "http://www.shareasale.com/r.cfm?u=882338&b=358708&m=37742&afftrack=&urllink=www%2Ebotach%2Ecom%2Ffnh%2Dscar%2D17s%2D7%2D62mm%2Dbattle%2Drifles%2Dtan%2F"

        result = DeriveAttributes.call(
            site:         site,
            listing:      @listing.merge(url: { page: url }),
            listing_json: @listing_json,
        )
        expect(result.listing.url.purchase).to eq(sas_link)
      end

      it 'returns the tagged url for a site with a link tag' do
        site = Site.new(domain: 'www.luckygunner.com', source: :fixture)
        site.send(:write_to_redis)
        url = "http://#{site.domain}/product"
        tagged_url = "#{url}#{site.affiliate_link_tag}"
        result = DeriveAttributes.call(
            site:         site,
            listing:      @listing.merge(url: { page: url }),
            listing_json: @listing_json,
        )
        expect(result.listing.url.purchase).to eq(tagged_url)

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
end
