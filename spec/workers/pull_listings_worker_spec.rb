require 'spec_helper'

describe PullListingsWorker do
  class Mapper
    include ObjectMapper
  end

  before :each do
    # IronGrid
    @site = create_site "www.retailer.com"
    @not_found_redirect = "http://#{@site.domain}/"
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!

    # Vars
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

    @listing = FactoryGirl.build(:listing, :retail, seller: { site_name: @site.name, domain: @site.domain })
    @listing_json = Mapper.new.reverse_map(@listing).to_hash.merge(valid: true)
    @listing_data = @listing.data.merge(id: @listing.id)
  end

  describe '#perform' do
    describe 'Existing listing' do
      it 'updates a listing with new attributes' do
        existing_listing = IronBase::Listing.create(@listing_data)
        page = @page.merge(url: existing_listing.url.page)
        new_listing_json = @listing_json.merge(title: 'Updated Listing')

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

      it 'updates a feed listing with new attributes' do
        Rails.logger.info "##  Creating existing listing..."
        existing_listing = IronBase::Listing.create(@listing_data)
        Rails.logger.info "## Created #{existing_listing.id} with digest #{existing_listing.digest}"
        existing_listing.url.page = 'http://www.retailer.com/feed.xml'
        existing_listing.save
        Rails.logger.info "##  Saved existing listing #{existing_listing.id} with digest #{existing_listing.digest}"

        IronBase::Listing.refresh_index
        page = @page.merge(url: existing_listing.url.page)

        new_listing_json = @listing_json.merge(
            title: 'Updated Listing',
            url: existing_listing.url.purchase,
        )

        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        Rails.logger.info "##  Running worker"
        @worker.perform(domain: @site.domain)
        Rails.logger.info "## Worker finished!"
        IronBase::Listing.refresh_index
        expect(IronBase::Listing.count).to eq(1)
        listing = IronBase::Listing.first
        expect(listing.title).to eq('Updated Listing')
        expect(listing.id).to eq(existing_listing.id)
        expect(listing.url.page).to eq(existing_listing.url.page)
        expect(listing.url.purchase).to eq(existing_listing.url.purchase)
        expect(updated_today?(listing)).to be_true
      end

      it 'deactivates an invalid feed listing' do
        existing_listing = IronBase::Listing.create(@listing_data)
        existing_listing.url.page = 'http://www.retailer.com/feed.xml'
        existing_listing.save
        IronBase::Listing.refresh_index

        page = @page.merge(url: 'http://www.retailer.com/feed.xml')

        new_listing_json = @listing_json.merge(
            title: 'Updated Listing',
            url: existing_listing.url.purchase,
            valid: false
        )

        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        listing = IronBase::Listing.first

        expect(listing.inactive?).to be_true
        expect(listing.digest).to eq(existing_listing.digest)
        expect(listing.url.purchase).to eq(existing_listing.url.purchase)
        expect(listing.url.page).to eq(existing_listing.url.page)
        expect(listing.id).to eq(existing_listing.id)
        expect(updated_today?(listing)).to be_true
      end

      it 'deactivates an invalid retail listing' do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        page = @page.merge(url: existing_listing.url)
        new_listing_json = @listing_json.merge(valid: false)

        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        listing = IronBase::Listing.first

        expect(listing.inactive?).to be_true
        expect(listing.digest).to eq(existing_listing.digest)
        expect(listing.url.purchase).to eq(existing_listing.url.purchase)
        expect(listing.url.page).to eq(existing_listing.url.page)
        expect(listing.id).to eq(existing_listing.id)
        expect(updated_today?(listing)).to be_true
      end

      it 'deletes a listing that redirects to an invalid page' do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        page = @page.merge(
            url: @not_found_redirect,
            redirect_from: existing_listing.url.page,
            code: 301
        )
        new_listing_json = @listing_json.merge(valid: false)
        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        expect(IronBase::Listing.search).to be_empty
      end

      it 'deletes a listing that redirects to a not_found page' do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        page = @page.merge(
            url: @not_found_redirect,
            redirect_from: existing_listing.url.page,
            code: 301
        )
        new_listing_json = @listing_json.merge(valid: false)
        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        expect(IronBase::Listing.search).to be_empty
      end

      it 'updates a listing that 301 moved permanently with a new url' do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        redirect_url = "#{existing_listing.url.page}123"
        page = @page.merge(
            url: redirect_url,
            redirect_from: existing_listing.url.page,
            code: 301
        )
        @object_q.add @object.merge(
                          object: @listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index

        listing = IronBase::Listing.first
        expect(listing.url.page).to eq(redirect_url)
        expect(listing.digest).to eq(existing_listing.digest)
        expect(updated_today?(listing)).to be_true
      end

      it 'updates a listing that 302 moved temporarily, but keeps original url' do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        redirect_url = "#{existing_listing.url.page}123"
        page = @page.merge(
            url: redirect_url,
            redirect_from: existing_listing.url.page,
            code: 302
        )
        @object_q.add @object.merge(
                          object: @listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index

        listing = IronBase::Listing.first
        expect(listing.url.page).to eq(existing_listing.url.page)
        expect(listing.digest).to eq(existing_listing.digest)
        expect(updated_today?(listing)).to be_true
      end

      it "deletes a listing that 404s" do
        existing_listing = IronBase::Listing.create(@listing_data)
        IronBase::Listing.refresh_index
        page = @page.merge(
            url:  existing_listing.url.page,
            code: 404
        )
        @object_q.add @object.merge(
                          object: @listing_json,
                          page:   page
                      )

        @worker.perform(domain: @site.domain)
        IronBase::Listing.refresh_index
        expect(IronBase::Listing.search).to be_empty
      end

      it 'deletes a listing that is discovered to be a duplicate' do
        # A retail listing is created in the database
        listing_v1 = IronBase::Listing.create(@listing_data)

        # Later, that same listing moves (HTTP 301) to a new url and goes on sale,
        # so that the url, price, an digest are all different. This platform will
        # therefore think this is a new listing, although it's really an updated
        # version of listing_v1.
        listing_data_v2 = @listing_data.merge(
            price: listing_v1.price.merge(sale: 1),
            url: {
                page: "#{listing_v1.url.page}-new-url",
                purchase: "#{listing_v1.url.page}-new-url"
            }
        )
        listing_v2 = IronBase::Listing.create(listing_data_v2)

        # Now when we try to refresh listing_v1, the platform will realize that
        # it has a dupe because the new url & digest for the refreshed listing_v1
        # already exists in the database as listing_v2. Therefore
        # we need to delete listing_v1.
        page = @page.merge(
            url:           listing_v2.url,
            redirect_from: listing_v1.url,
            code:           301
        )

        new_listing_json = Mapper.new.reverse_map(listing_v2).merge(
            valid: true,
        ).to_hash

        @object_q.add @object.merge(
                          object: new_listing_json,
                          page:   page
                      )

        expect(IronBase::Listing.search.size).to eq(1)
        expect(Listing.find(listing_v1.id)).to be_nil
        listing = Listing.find(listing_v2.id)

        expect(listing.url).to eq(page[:url])
        expect(listing.digest).to eq(listing_v2.digest)
        expect(updated_today?(listing)).to be_true
      end
    end

    it "pops objects from the ObjectQueue for the domain" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(@object_q.size).to eq(0)
    end

    describe "write to listings table from a generic full product feed" do
      before :each do
        @site = create_site "ammo.net"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear

        Stretched::Registration.clear_all
        register_globals
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
        register_globals
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

