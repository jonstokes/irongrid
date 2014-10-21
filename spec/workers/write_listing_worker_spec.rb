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
      "url"                   => nil,
      "digest"                => "aaaa",
      "type"                  => "RetailListing",
      "seller_domain"         => @site.domain,
      "image"                 => "http://cdn.ironsights.com/1235.jpg",
      "item_data" => {
        "title"               => [
          {"title" => "Foo"},
          {"scrubbed" => "bar"},
          {"normalized" => "qux"},
          {"autocomplete" => "baz"}
        ],
        "description"         => Faker::Lorem.paragraph,
        "keywords"            => Faker::Lorem.sentence,
        "image_source"        => "http://www.retailer.com/img.jpg",
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
    }
    @page = {
      'code'          => 200,
    }
  end

  describe "#existing_listing" do
    it "updates a listing with new attributes" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge('url' => existing_listing.url)

      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'success'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq(existing_listing.url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
    end

    it "updates a feed listing with new attributes" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url' => 'http://www.retailer.com/feed.xml'
      )
      listing_data = @listing_data.merge(
        'url'    =>  existing_listing.url,
        'digest' => 'bbbb'
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: listing_data,
        status:  'success'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq(existing_listing.url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
    end

    it "deactivates an invalid feed listing" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url' => 'http://www.retailer.com/feed.xml'
      )
      listing_data = @listing_data.merge(
        'url'    => existing_listing.url,
        'digest' => 'bbbb'
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: listing_data,
        status:  'invalid'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq(existing_listing.digest)
      expect(listing.url).to eq(existing_listing.url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
      expect(listing.inactive?).to be_true
    end

    it "deactivates an invalid retail listing" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge('url' => existing_listing.url)

      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'invalid'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq(existing_listing.digest)
      expect(listing.url).to eq(existing_listing.url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
      expect(listing.active?).to be_false
    end

    it "deletes a listing that redirects to an invalid page" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url'           => @not_found_redirect,
        'redirect_from' => existing_listing.url,
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'invalid'
      )
      expect(Listing.count).to eq(0)
    end

    it "deletes a listing that redirects to a not_found page" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url'           => @not_found_redirect,
        'redirect_from' => existing_listing.url,
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'not_found'
      )
      expect(Listing.count).to eq(0)
    end

    it "updates a listing that 301 moved permanently with a new url" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url'           => @redirect_url,
        'redirect_from' => existing_listing.url,
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'success'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq(@redirect_url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
    end

    it "updates a listing that 302 moved temporarily, but keeps original url" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url'           => @redirect_url,
        'redirect_from' => existing_listing.url,
        'code'          => 302
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'success'
      )
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq(existing_listing.url)
      expect(listing.update_count).to eq(1)
      expect(updated_today?(listing)).to be_true
    end

    it "deletes a listing that 404s" do
      existing_listing = FactoryGirl.create(:retail_listing, :stale)
      page = @page.merge(
        'url'           => existing_listing.url,
        'code'          => 404
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => "bbbb"),
        status:  'not_found'
      )
      expect(Listing.count).to eq(0)
    end

    it "deletes a listing that is discovered to be a duplicate" do
      # A retail listing is created in the database
      listing_v1 = FactoryGirl.create(:retail_listing, :stale)

      # Later, that same listing moves (HTTP 301) to a new url and goes on sale,
      # so that the url, price, an digest are all different. This platform will
      # therefore think this is a new listing, although it's really an updated
      # version of listing_v1.
      listing_v2 = FactoryGirl.create(:retail_listing)

      # Now when we try to refresh listing_v1, the platform will realize that
      # it has a dupe because the new url & digest for the refreshed listing_v1
      # already exists in the database as listing_v2. Therefore
      # we need to delete listing_v1.
      page = @page.merge(
        'url'           => listing_v2.url,
        'redirect_from' => listing_v1.url,
        'code'          => 301
      )
      WriteListingWorker.new.perform(
        page:    page,
        listing: @listing_data.merge("digest" => listing_v2.digest),
        status:  'success'
      )
      expect(Listing.count).to eq(1)
      expect { Listing.find(listing_v1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      listing = Listing.find(listing_v2.id)

      expect(listing.url).to eq(page['url'])
      expect(listing.digest).to eq(listing_v2.digest)
      expect(updated_today?(listing)).to be_true
    end

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
