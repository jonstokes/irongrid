require 'spec_helper'

describe WriteListingWorker do

  before :each do
    @site = create_site_from_repo "www.retailer.com"
    geo_data = FactoryGirl.create(:geo_data)
    @valid_attrs =  {
      "url"                   => "http://www.retailer.com/1",
      "digest"                => "aaaa",
      "type"                  => "RetailListing",
      "geo_data_id"           => geo_data.id,
      "item_data" => {
        "title"               => [
          {"title" => "Foo"},
          {"scrubbed" => "bar"},
          {"normalized" => "qux"},
          {"autocomplete" => "baz"}
        ],
        "description"         => Faker::Lorem.paragraph,
        "keywords"            => Faker::Lorem.sentence,
        "image"               => "http://cdn.ironsights.com/1235.jpg",
        "image_source"        => "http://www.retailer.com/img.jpg",
        "item_location"       => geo_data.key,
        "seller_domain"       => @site.domain,
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
  end

  describe "#new_listing" do
    it "creates a new valid listing" do
      LinkData.create(
        url:             @valid_attrs["url"],
        page_attributes: @valid_attrs,
        page_is_valid:   true,
        page_not_found:  false,
      )
      WriteListingWorker.new.perform(@valid_attrs["url"])
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("aaaa")
      expect(listing.type).to eq("RetailListing")
      expect(listing.seller_name).to eq(@site.name)
      expect(listing.seller_domain).to eq(@site.domain)
      expect(listing.item_condition).to eq("New")
    end

    it "does not create a duplicate listing" do
      Listing.create(@valid_attrs)
      attrs = @valid_attrs.merge("url" => "http://www.retailer.com/2")
      LinkData.create(
        url:             attrs["url"],
        page_attributes: attrs,
        page_is_valid:   true,
        page_not_found:  false
      )
      WriteListingWorker.new.perform(attrs["url"])
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.url).to eq(@valid_attrs["url"])
    end
  end

  describe "#existing_listing" do
    before :each do
      Listing.create(@valid_attrs)
    end

    it "updates a listing with new attributes" do
      url = @valid_attrs["url"]
      LinkData.create(
        url:             url,
        page_attributes: @valid_attrs.merge("digest" => "bbbb"),
        page_is_valid:   true,
        page_not_found:  false,
      )
      WriteListingWorker.new.perform(url)
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq(url)
    end

    it "does nothing if the listing hasn't changed" do
      url = @valid_attrs["url"]
      LinkData.create(
        url:             url,
        page_attributes: @valid_attrs,
        page_is_valid:   true,
        page_not_found:  false,
      )
      expect(Listing).not_to receive(:duplicate_digest?)
      WriteListingWorker.new.perform(url)
    end

    it "deletes a not_found listing" do
      url = @valid_attrs["url"]
      LinkData.create(
        url:             url,
        page_attributes: nil,
        page_is_valid:   false,
        page_not_found:  true,
      )
      WriteListingWorker.new.perform(url)
      expect(Listing.count).to eq(0)
    end

    it "deactivates an invalid listing" do
      url = @valid_attrs["url"]
      LinkData.create(
        url:             url,
        page_attributes: @valid_attrs.merge("digest" => "bbbb"),
        page_is_valid:   false,
        page_not_found:  false,
      )
      WriteListingWorker.new.perform(url)
      expect(Listing.count).to eq(1)
      expect(Listing.first.inactive).to be_true
    end

    it "deletes a listing that, as a result of an update, is now a duplicate" do
      # This scenario is complicated, so I'll spell it out:
      # 1. Listing 1 exists in the db url retailer.com/1 and digest "aaaa"
      # 2. Retailer has brought up a product page that's a duplicate of listing 1, but
      #    with, say, an updated price at retailer.com/1+product-name. (This is often done
      #    for SEO purposes.) So when this page is scraped it will look like a new page
      #    because it has new url and a new digest, but really it's the same listing.
      # 3. After a crawl, this newer version of Listing 1 will exist in the db alongside
      #    the original listing 1, so there will be two different versions of the same
      #    listing at two different urls and db rows.
      # 4. When Listing 1's url is put back into the LinkQueue to be refreshed, its page
      #    will now have the same digest and attributes as the new version, so Listing 1
      #    can now be identified as a dupe and deleted, leaving only the newer version
      #    in the db.

      # The original listing is in the db, so write the dup to the db
      Listing.create(@valid_attrs.merge("url" =>"http://www.retailer.com/1+1", "digest" => "bbbb"))

      # There are now two versions of the same listing in the db:
      # Original: url is retailer.com/1 and digest is "aaaa"
      # Newer: url is retailer.com/1+1 and digest is "bbbb"
      expect(Listing.count).to eq(2)

      # Now let's pretend we refreshed the original (but now stale) listing by running
      # RefreshLinksWorker and CreateLinksWorker on the domain, resulting
      # in the new version of the page in redis.
      LinkData.create(
        url:             @valid_attrs["url"],
        page_attributes: @valid_attrs.merge("digest" => "bbbb"),
        page_is_valid:   true,
        page_not_found:  false,
      )

      # The worker should delete the original, stale listing and leave
      # only the newer updated listing at the new url
      WriteListingWorker.new.perform(@valid_attrs["url"])
      expect(Listing.count).to eq(1)
      listing = Listing.first
      expect(listing.digest).to eq("bbbb")
      expect(listing.url).to eq("http://www.retailer.com/1+1")
    end
  end
end
