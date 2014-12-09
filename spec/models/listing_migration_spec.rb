require 'spec_helper'

describe ListingMigration do

  before :each do
    @site = create_site 'www.budsgunshop.com'
    register_globals
    register_site @site.domain
    load_scripts
    location = create(:geo_data)
    @title = 'Listing title'
    @caliber = '.45 ACP'
    @listing_attrs = {
        url: "http://#{@site.domain}/1",
        digest: 'abcd123',
        upc: '10001',
        sku: 'sku-10001',
        mpn: 'mpn-10001',
        type: 'RetailListing',
        image: 'http://assets.scoperrific.com/1.jpg',
        image_download_attempted: true,
        seller_domain: @site.domain,
        auction_ends: Time.now,
        item_data: {
            title: [ { 'title' => @title } ],
            description: 'Listing description',
            shipping_cost_in_cents: 90,
            discount_in_cents: 100,
            weight_in_pounds: 2,
            seller_name: @site.name,
            image_source: "http://#{@site.domain}/image.jpg",
            item_condition: 'new',
            item_location: location.key,
            availability: 'in_stock',
            current_price_in_cents: 1000,
            price_in_cents: 1100,
            sale_price_in_cents: 1000,
            caliber: [ { 'caliber' => @caliber } ],
            caliber_category: [ { 'caliber_category' => 'handgun' } ],
            manufacturer: [ { 'manufacturer' => 'Remington' } ],
            category1: [ { 'category1' => 'Ammunition' } ],
            grains: [ { 'grains' => 101 } ],
            material: 'brass',
            number_of_rounds: [ { 'number_of_rounds' => 10 } ],
            price_per_round_in_cents: 10,
            city: location.city,
            state: location.state,
            country: location.country,
            latitude: location.latitude,
            longitude: location.longitude,
            state_code: location.state_code,
            postal_code: location.postal_code,
            country_code: location.country_code,
            coordinates: location.coordinates
        }
    }
    @listing_attrs.deep_stringify_keys!
  end

  describe 'write_listing_to_index' do
    it 'writes a listing to the index in the new ES format' do
      attrs = Hashie::Mash.new(@listing_attrs)
      listing = Listing.create(@listing_attrs)
      migration = ListingMigration.new(listing)
      migration.write_listing_to_index
      IronBase::Listing.refresh_index

      expect(IronBase::Listing.count).to eq(1)
      expect(IronBase::Product.count).to eq(1)

      listing = IronBase::Listing.first
      product = IronBase::Product.first
      location = IronBase::Location.first

      expect(listing.title).to eq(@title)
      expect(listing.price.current).to eq(attrs.item_data.current_price_in_cents)
      expect(listing.price.list).to eq(attrs.item_data.price_in_cents)
      expect(listing.price.sale).to eq(attrs.item_data.sale_price_in_cents)
      expect(listing.availability).to eq(attrs.item_data.availability)
      expect(listing.condition).to eq(attrs.item_data.item_condition)
      expect(listing.location.city).to eq(attrs.item_data.city)
      expect(listing.location.id).to eq(location.id)
      expect(listing.product.id).to eq(product.id)

      expect(location.city).to eq(attrs.item_data.location.city)
      expect(location.coordinates).to eq(attrs.item_data.location.coordinates)
      expect(location.id).to eq(attrs.item_data.item_location)

      expect(listing.product.upc).to eq([attrs.upc])
      expect(listing.product.caliber).to eq(@caliber)

      expect(product.name).to eq(@title)
    end

    it 'also writes a product to the index' do
      pending 'Example'
    end
  end

  describe 'verify' do
    it 'verifies the url format of the new listing' do
      pending 'Example'
    end
  end

  describe 'fix_listing_metadata' do
    it 'fixes the caliber_category for a listing when necessary' do
      pending 'Example'
    end

    it 'Only returns a hard-categorized category' do
      pending 'Example'
    end

    it 'copies over the timestamps for a listing' do
      pending 'Example'
    end
  end

  describe 'json' do
    it 'formats a listing as stretched_json' do
      pending "Example"
    end
  end

  describe 'page_url' do
    it 'gives the feed url for a feed listing' do
      pending "Example"
    end

    it 'gives the bare_url for a non-feed listing' do
      pending "Example"
    end
  end

  describe 'listing_url' do
    it 'gives the bare_url for a feed listing' do
      pending "EXample"
    end

    it 'gives nil for a non-feed listing' do
      pending "Example"
    end
  end
end