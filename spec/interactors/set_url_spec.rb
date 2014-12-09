require 'spec_helper'

describe WriteListingToIndex::SetUrl do
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
    @page = Hashie::Mash.new(
        url: "http://#{@site.domain}/1",
        code: 200
    )
  end

  describe '#purchase_url' do
    it 'returns the untagged url for a site without a link tag' do
      result = WriteListingToIndex::SetUrl.call(
          site:         @site,
          page:         @page,
          listing_json: @listing_json,
      )
      expect(result.url.purchase).to eq(@page.url)
    end

    it 'returns an affiliate url for ShareASale site' do
      site = create_site 'www.botach.com'
      url = 'http://www.botach.com/fnh-scar-17s-7-62mm-battle-rifles-tan/'
      sas_link = "http://www.shareasale.com/r.cfm?u=882338&b=358708&m=37742&afftrack=&urllink=www%2Ebotach%2Ecom%2Ffnh%2Dscar%2D17s%2D7%2D62mm%2Dbattle%2Drifles%2Dtan%2F"

      result = WriteListingToIndex::SetUrl.call(
          site:         site,
          page:         @page.merge(url: "http://#{site.domain}/feed.xml"),
          listing_json: @listing_json.merge(url: url),
      )
      expect(result.url.purchase).to eq(sas_link)
    end

    it 'returns the tagged url for a site with a link tag' do
      site = Site.new(domain: 'www.luckygunner.com', source: :fixture)
      site.send(:write_to_redis)
      url = "http://#{site.domain}/product"
      tagged_url = "#{url}#{site.affiliate_link_tag}"
      result = WriteListingToIndex::SetUrl.call(
          site:         site,
          page:         @page.merge(url: url),
          listing_json: @listing_json,
      )
      expect(result.url.purchase).to eq(tagged_url)

    end
  end
end