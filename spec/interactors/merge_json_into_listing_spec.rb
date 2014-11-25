require 'spec_helper'

describe MergeJsonIntoListing do
  describe '#call', no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
      @url = Hashie::Mash.new(
          purchase: "http://#{@site.domain}/product/1",
          page: "http://#{@site.domain}/product/1"
      )
      @listing_json = Hashie::Mash.new(
          id:                     @url.purchase,
          valid:                  true,
          url:                    @url,
          condition:              'new',
          type:                   'RetailListing',
          availability:           'in_stock',
          location:               '1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705',
          image:                  'http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG',
          price_in_cents:         65000,
          sale_price_in_cents:    60000,
          current_price_in_cents: 60000,
          shipping_cost_in_cents: 200,
          description:            ".45ACP, 3 1/2\" BARREL, HOGUE BLACK GRIPS"
      )
      @listing = IronBase::Listing.new(
          type: 'RetailListing',
          url: { page: 'http://www.retailer.com/1' }
      )
    end

    it 'correctly copies attributes for a listing' do
      listing = MergeJsonIntoListing.call(
        site:         @site,
        listing_json: @listing_json,
        listing:      @listing,
        url:          @url
      ).listing

      expect(listing.url.page).to eq(@url.page)
      expect(listing.url.purchase).to eq(@url.purchase)
      expect(listing.condition).to eq('new')
      expect(listing.location.source).to eq('1900 East Warner Ave. Ste., 1-D, Santa Ana, CA 92705')
      expect(listing.type).to eq('RetailListing')
      expect(listing.availability).to eq('in_stock')
      expect(listing.price.list).to eq(65000)
      expect(listing.price.sale).to eq(60000)
      expect(listing.shipping.cost).to eq(200)
      expect(listing.seller.domain).to eq(@site.domain)
      expect(listing.seller.site_name).to eq(@site.name)
    end

    it 'correctly sets common attributes for an auction listing' do
      listing_json = @listing_json.merge(
          type:         'AuctionListing',
          auction_ends: '09/10/2025 11:00:00' #Central Time is default zone
      )
      result = MergeJsonIntoListing.call(
          site:         @site,
          listing:      @listing,
          listing_json: listing_json
      )
      expect(result.listing.auction_ends.to_s).to eq('2025-09-10 16:00:00 UTC')
    end

    it 'fails if the auction is ended' do
      @listing.type = 'AuctionListing'
      listing_json = @listing_json.merge(
          type:         'AuctionListing',
          auction_ends: 2.hours.ago
      )
      result = MergeJsonIntoListing.call(
          site:         @site,
          listing:      @listing,
          listing_json: listing_json
      )
      expect(result.success?).to eq(false)
      expect(result.status).to eq(:auction_ended)
    end
  end
end
