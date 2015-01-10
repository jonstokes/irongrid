require 'spec_helper'

describe WriteListingToIndex::FindOrCreateListing do
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

  describe '#call' do
    it 'retrieves a listing object for a listing that already exists in the index' do
      listing = create(:listing)
      listing_json = Hashie::Mash.new(ObjectMapper.json_from_listing(listing))
      page = Hashie::Mash.new(
          code: 200,
          url: listing.url.page
      )
      IronBase::Listing.refresh_index

      listing2 = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          page:         page,
          url:          listing.url,
          site:         @site
      ).listing

      expect(listing2.persisted?).to eq(true)
      expect(IronBase::Listing.count).to eq(1)
      expect(IronBase::Listing.find(listing2.id).id).to eq(listing.id)
    end

    it 'returns a new, unsaved listing object when a listing with this id does not exist in the index' do
      listing_json = Hashie::Mash.new(
          title: 'New Listing'
      )
      page = Hashie::Mash.new(
          code: 200,
          url: 'http://www.retailer.com/1'
      )
      IronBase::Listing.refresh_index

      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          url: Hashie::Mash.new(page: page.url, purchase: page.url),
          page: page,
          site: @site
      ).listing

      expect(listing.persisted?).to eq(false)
      expect(IronBase::Listing.count).to eq(0)
      expect(IronBase::Listing.find(listing.id)).to be_nil
    end
  end

  describe '#purchase_url' do
    it 'returns the untagged url for a site without a link tag' do
      listing = WriteListingToIndex::FindOrCreateListing.call(
          site:         @site,
          page:         @page,
          listing_json: @listing_json,
      ).listing
      expect(listing.url.purchase).to eq(@page.url)
    end

    it 'returns an affiliate url for ShareASale site' do
      site = create_site 'www.botach.com'
      url = 'http://www.botach.com/fnh-scar-17s-7-62mm-battle-rifles-tan/'
      sas_link = "http://www.shareasale.com/r.cfm?u=882338&b=358708&m=37742&afftrack=&urllink=www%2Ebotach%2Ecom%2Ffnh%2Dscar%2D17s%2D7%2D62mm%2Dbattle%2Drifles%2Dtan%2F"

      listing = WriteListingToIndex::FindOrCreateListing.call(
          site:         site,
          page:         @page.merge(url: "http://#{site.domain}/feed.xml"),
          listing_json: @listing_json.merge(url: url),
      ).listing
      expect(listing.url.purchase).to eq(sas_link)
    end

    it 'returns an affiliate url for an AvantLink site' do
      site = create_site 'www.brownells.com'
      url = 'http://www.brownells.com/ammunition/handgun-ammo/45-auto-185gr-z-max-20bx-10ca-hdy90902-sku105000034-45019-102120.aspx'
      aff_link = 'http://www.avantlink.com/click.php?tt=cl&mi=10077&pw=151211&url=http%3A%2F%2Fwww.brownells.com%2Fammunition%2Fhandgun-ammo%2F45-auto-185gr-z-max-20bx-10ca-hdy90902-sku105000034-45019-102120.aspx'

      listing = WriteListingToIndex::FindOrCreateListing.call(
          site:         site,
          page:         @page.merge(url: "http://#{site.domain}/feed.xml"),
          listing_json: @listing_json.merge(url: url),
      ).listing
      expect(listing.url.purchase).to eq(aff_link)
    end

    it 'returns the tagged url for a site with a link tag' do
      site = Site.new(domain: 'www.luckygunner.com', source: :fixture)
      site.send(:write_to_redis)
      url = "http://#{site.domain}/product"
      tagged_url = "#{url}#{site.affiliate_link_tag}"

      listing = WriteListingToIndex::FindOrCreateListing.call(
          site:         site,
          page:         @page.merge(url: url),
          listing_json: @listing_json,
      ).listing
      expect(listing.url.purchase).to eq(tagged_url)
    end
  end

  describe '#listing_id' do
    it 'should use the purchase url when there is no id tag' do
      page_url = 'http://www.retailer.com'
      purchase_url = "#{page_url}-buy"
      listing_json = Hashie::Mash.new(
          title: 'New Listing',
          url: purchase_url
      )
      page = Hashie::Mash.new(
          code: 200,
          url: page_url
      )

      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          page: page,
          site: @site
      ).listing

      expect(listing.id).to eq(Digest::MD5.hexdigest(purchase_url))
    end

    it 'should use an id tagged url when there is an id tag in the listing json' do
      id_tag = '-123'
      page_url = 'http://www.retailer.com'
      purchase_url = "#{page_url}-buy"
      listing_json = Hashie::Mash.new(
          title: 'New Listing',
          id: id_tag,
          url: purchase_url
      )

      page = Hashie::Mash.new(
          code: 200,
          url: page_url
      )

      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          page: page,
          site: @site
      ).listing

      expect(listing.id).to eq(Digest::MD5.hexdigest("#{purchase_url}#{id_tag}"))
    end
  end
end