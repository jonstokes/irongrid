require 'spec_helper'

describe PullListingsWorker do
  class Mapper
    include ObjectMapper
  end

  before :each do
    # IronGrid
    @site = create_site "www.retailer.com"
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!

    # Vars
    @listing_json = {
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
      "product_sku"         => "1911-CIT45CSPHB",
    }
    @worker = PullListingsWorker.new
    @page = {
        url:     "http://#{@site.domain}/1",
        headers: "",
        code:    200,
        body:    true,
        error:   nil,
        fetched: true,
        response_time: 100
    }
    @object = {
      session: {},
      page: @page,
      object: @listing_json
    }
    @object_q = Stretched::ObjectQueue.new("#{@site.domain}/listings")
  end

  describe '#perform' do
    describe 'Existing listing' do
      it 'updates a listing with new attributes' do
        existing_listing = create(:listing, :retail)
        page = @page.merge(url: existing_listing.url.page)
        new_listing_json = Mapper.new.reverse_map(existing_listing).merge(
            title: 'Updated Listing',
            valid: true
        ).to_hash

        @object_q.add @object.merge(
            object: new_listing_json,
            page:   page
        )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        expect(IronBase::Listing.count).to eq(1)
        listing = IronBase::Listing.first
        expect(listing.title).to eq('Updated Listing')
        expect(listing.url).to eq(existing_listing.url)
        expect(listing.persisted?).to be_true
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



    it "pops objects from the ObjectQueue for the domain" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
    end

    it "correctly tags a 404 link" do
      @object[:page].merge!(body: false, code: 404)
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      args = Hashie::Mash.new job["args"].first
      expect(args.status).to eq('not_found')
      expect(args.page.code).to eq(404)
    end

    it "correctly tags a not_found link in redis" do
      @object[:object] = {
        "seller_domain" => @site.domain,
        "not_found"     => true,
        "title"         => "Title"
      }
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      args = Hashie::Mash.new job["args"].first
      expect(args.status).to eq('not_found')
    end

    it "correctly tags an invalid link in redis" do
      @object[:object] = {
        "seller_domain" => @site.domain,
        "not_found"     => false,
        "valid"         => false,
        "title"         => "Title"
      }
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      args = Hashie::Mash.new job["args"].first
      expect(args.status).to eq('invalid')
    end

    it "correctly tags a valid link in redis" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      args = Hashie::Mash.new job["args"].first
      expect(args.status).to eq('success')
      expect(args.listing["digest"]).to eq("862e3a129f9da0c4a4ffdef2d4a6cb09")
    end

    describe "write to listings table from a generic full product feed" do
      before :each do
        @site = create_site "ammo.net"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear

        Stretched::Registration.clear_all
        register_stretched_globals
        @site.register
        @object_q = Stretched::ObjectQueue.new("#{@site.domain}/listings")
      end

      it "should create WriteListingWorkers for new listings with proper payload" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/full_product_feed.json") do |f|
          JSON.parse(f.read)
        end

        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        expect(WriteListingWorker._jobs.count).to eq(18)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        expect(args.listing.url).to match(/ammo\.net/)
        expect(args.listing.digest).not_to be_nil
        expect(args.status).to eq('success')
      end

      it "should create WriteListingWorkers for modified listings with proper payload" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/full_product_feed_updates.json") do |f|
          JSON.parse(f.read)
        end

        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        expect(WriteListingWorker._jobs.count).to eq(18)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        expect(args.listing.url).to match(/ammo\.net/)
        expect(args.listing.digest).not_to be_nil
        expect(args.status).to eq('success')
        expect(args.listing.item_data["price_in_cents"]).to eq(1150)
      end

      it "should add a link to the ImageQueue for each new or updated listing" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/full_product_feed.json") do |f|
          JSON.parse(f.read)
        end
        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        iq = ImageQueue.new(domain: @site.domain)
        expect(iq.size).to eq(18)
        expect(iq.pop).to match(/cloudfront\.net/)
      end
    end

    describe "write to listings table from Avantlink feed" do
      before :each do
        @site = create_site "www.brownells.com"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear

        Stretched::Registration.clear_all
        register_stretched_globals
        @site.register
        @object_q = Stretched::ObjectQueue.new("#{@site.domain}/listings")
      end

      it "should create WriteListingWorkers for new listings with proper payload" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/test_feed.json") do |f|
          JSON.parse(f.read)
        end
        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        expect(WriteListingWorker._jobs.count).to eq(4)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        expect(args.listing.url).to match(/avantlink\.com/)
        expect(args.listing.digest).not_to be_nil
        expect(args.status).to eq('success')
      end

      it "should create WriteListingWorkers for modified listings with proper payload" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/test_feed_update.json") do |f|
          JSON.parse(f.read)
        end
        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        expect(WriteListingWorker._jobs.count).to eq(4)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        expect(args.listing.url).to match(/avantlink\.com/)
        expect(args.listing.digest).not_to be_nil
        expect(args.status).to eq('success')
        expect(args.listing.item_data["price_in_cents"]).to eq(109)
      end

      it "should create WriteListingWorkers for removed listings proper payload" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/test_feed_remove.json") do |f|
          JSON.parse(f.read)
        end
        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        expect(WriteListingWorker._jobs.count).to eq(4)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        expect(args.listing.url).to match(/avantlink\.com/)
        expect(args.listing.item_data['availability']).to eq('out_of_stock')
        expect(args.status).to eq('success')
      end

      it "should add a link to the ImageQueue for each new or updated listing" do
        objects = File.open("#{Rails.root}/spec/fixtures/stretched/output/test_feed.json") do |f|
          JSON.parse(f.read)
        end
        @object_q.add(objects)

        @worker.perform(domain: @site.domain)
        iq = ImageQueue.new(domain: @site.domain)
        expect(iq.size).to eq(4)
        expect(iq.pop).to match(/brownells\.com/)
      end
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source and does not add image_source to the ImageQueue" do
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        CDN::Image.create(source: image_source, http: Sunbro::HTTP.new)
        @object_q.add(@object)
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        iq = ImageQueue.new(domain: @site.domain)

        expect(args.listing["item_data"]["image_source"]).to eq(image_source)
        expect(args.listing["item_data"]["image"]).to eq("https://s3.amazonaws.com/scoperrific-index-test/c8f0568ee6c444af95044486351932fb.JPG")
        expect(iq.pop).to be_nil
      end
    end

    describe "where image_source does not exist on CDN already" do
      it "adds the image_source url to the ImageQueue and sets 'image' attribute to default" do
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        @object_q.add(@object)
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker._jobs.first
        args = Hashie::Mash.new job["args"].first
        iq = ImageQueue.new(domain: @site.domain)

        expect(args.listing["item_data"]["image_source"]).to eq(image_source)
        expect(args.listing["item_data"]["image"]).to eq(CDN::DEFAULT_IMAGE_URL)
        expect(iq.pop).to eq(image_source)
      end
    end
  end

  describe "#transition" do
    it "transitions to self if it times out while the site's ObjectQueue is not empty" do
      pending "Example"
    end

    it "does not transition to self if the site's ObjectQueue is empty" do
      pending "Example"
    end
  end

end

