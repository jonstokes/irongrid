require 'spec_helper'

def updated_today?(listing)
  update = Time.parse(listing.updated_at)
  update >= Time.now
end

describe WriteListingWorker do

  # The desired behaviors for the following scenarios are broken out
  # in a table here: http://goo.gl/20W6DF

  before :each do
    @site = create_site "www.retailer.com"
    @geo_data = FactoryGirl.create(:geo_data)
    @redirect_url = "http://www.retailer.com/new-listing-location"
    @not_found_redirect = "http://www.retailer.com/"

    @listing_data =  {
      url:                    nil,
      digest:                 "aaaa",
      type:                   "RetailListing",
      seller_domain:          @site.domain,
      image:                  'http://cdn.ironsights.com/1235.jpg',
      title:                  'Foo',
      description:            Faker::Lorem.paragraph,
      keywords:               Faker::Lorem.sentence,
      image:                  "http://www.retailer.com/img.jpg",
      "item_location"       => @geo_data.key,
      "seller_name"         => @site.name,
      "category1" => [
        { "category1"  => "guns" },
        { "classification_type"  => "hard" },
        { "score"  => "1" }
      ],
      "item_condition"      => "New",
      "stock_status"        => "In Stock",
      "price_in_cents"      => 1099,
      "sale_price_in_cents" => 999
    }
    @page = {
      code: 200,
    }
  end


  describe "#new_listing" do
    it "creates a new listing from a feed" do
      listing_data = @listing_data.merge(
        'url' => 'http://www.retailer.com/1'
      )
      page = @page.merge(
        'url' => 'http://www.retailer.com/feed.xml'
      )
      WriteListingWorker.new.perform(
        listing: listing_data,
        page:    page,
        status:  'success',
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(listing_data['url'])
      expect(listing.digest).to eq("aaaa")
      expect(listing.type).to eq("RetailListing")
      expect(listing.seller_name).to eq(@site.name)
      expect(listing.seller_domain).to eq(@site.domain)
      expect(listing.item_condition).to eq("New")
      expect(listing.city).to eq(@geo_data.city)
      expect(listing.coordinates).to eq(@geo_data.coordinates)
    end

    it "creates a new listing from a page" do
      page = @page.merge(
        'url' => 'http://www.retailer.com/1'
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'success',
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(page['url'])
      expect(listing.digest).to eq("aaaa")
      expect(listing.type).to eq("RetailListing")
      expect(listing.seller_name).to eq(@site.name)
      expect(listing.seller_domain).to eq(@site.domain)
      expect(listing.item_condition).to eq("New")
      expect(listing.city).to eq(@geo_data.city)
      expect(listing.coordinates).to eq(@geo_data.coordinates)
    end

    it "does not create a new listing for an invalid page" do
      page = @page.merge(
        'url' => 'http://www.retailer.com/1'
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'invalid',
      )
      expect(Listing.count).to eq(0)
    end

    it "does not create a new listing for a page that redirects to an invalid page" do
      page = @page.merge(
        'url'           => 'http://www.retailer.com/1',
        'redirect_from' => @not_found_redirect,
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'invalid',
      )
      expect(Listing.count).to eq(0)
    end

    it "creates a new listing from a 301 permanent redirect" do
      page = @page.merge(
        'url'           => @redirect_url,
        'redirect_from' => 'http://www.retailer.com/1',
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'success',
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(@redirect_url)
      expect(listing.digest).to eq("aaaa")
      expect(listing.type).to eq("RetailListing")
      expect(listing.seller_name).to eq(@site.name)
      expect(listing.seller_domain).to eq(@site.domain)
      expect(listing.item_condition).to eq("New")
      expect(listing.city).to eq(@geo_data.city)
      expect(listing.coordinates).to eq(@geo_data.coordinates)
    end

    it "creates a new listing from a 302 temporary redirect" do
      page = @page.merge(
        'url'           => @redirect_url,
        'redirect_from' => 'http://www.retailer.com/1',
        'code'          => 302
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'success',
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(page['redirect_from'])
      expect(listing.digest).to eq("aaaa")
      expect(listing.type).to eq("RetailListing")
      expect(listing.seller_name).to eq(@site.name)
      expect(listing.seller_domain).to eq(@site.domain)
      expect(listing.item_condition).to eq("New")
      expect(listing.city).to eq(@geo_data.city)
      expect(listing.coordinates).to eq(@geo_data.coordinates)
    end

    it "does not create a listing for a 404 page" do
      page = @page.merge(
        'url'           => 'http://www.retailer.com/1',
        'code'          => 404
      )
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page:    page,
        status:  'not_found',
      )
      expect(Listing.count).to eq(0)
    end

    it "does not create a listing for an invalid feed item" do
      listing_data = @listing_data.merge(
        'url' => 'http://www.retailer.com/1'
      )
      page = @page.merge(
        'url' => 'http://www.retailer.com/feed.xml'
      )

      WriteListingWorker.new.perform(
        listing: listing_data,
        page:    page,
        status:  'invalid',
      )
      expect(Listing.count).to eq(0)
    end

    it "does not create a duplicate listing" do
      url1 = "http://www.retailer.com/1"
      url2 = "http://www.retailer.com/2"
      Listing.create(@listing_data.merge("url" => url1))
      WriteListingWorker.new.perform(
        listing: @listing_data,
        page: @page.merge('url' => url2),
        status: 'success'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(url1)
    end
  end
end
