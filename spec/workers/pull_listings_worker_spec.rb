require 'spec_helper'
require 'sidekiq/testing'

describe PullListingsWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # Stretched
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals

    # IronGrid
    @site = create_site "www.retailer.com"
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
    @object = {
      session: {},
      page: @page,
      object: @listing_json
    }
    @object_q = Stretched::ObjectQueue.find_or_create("#{@site.domain}/listings")
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
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
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
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
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
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
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_false
    end

    it "correctly tags a valid link in redis" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_true
      expect(msg.page_attributes["digest"]).to eq("21831cde9254c9100fa5a8b2895d4b98")
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source and does not add image_source to the ImageQueue" do
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        CDN::Image.create(source: image_source, http: PageUtils::HTTP.new)
        @object_q.add(@object)
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker._jobs.first
        msg = LinkMessage.new(job["args"].first)
        iq = ImageQueue.new(domain: @site.domain)

        expect(msg.page_attributes["item_data"]["image_source"]).to eq(image_source)
        expect(msg.page_attributes["item_data"]["image"]).to eq("https://s3.amazonaws.com/scoperrific-index-test/c8f0568ee6c444af95044486351932fb.JPG")
        expect(iq.pop).to be_nil
      end
    end

    describe "where image_source does not exist on CDN already" do
      it "adds the image_source url to the ImageQueue and sets 'image' attribute to default" do
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        @object_q.add(@object)
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker._jobs.first
        msg = LinkMessage.new(job["args"].first)
        iq = ImageQueue.new(domain: @site.domain)

        expect(msg.page_attributes["item_data"]["image_source"]).to eq(image_source)
        expect(msg.page_attributes["item_data"]["image"]).to eq(CDN::DEFAULT_IMAGE_URL)
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

