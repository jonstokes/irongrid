require 'spec_helper'
require 'webmock/rspec'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe ScrapePagesWorker do
  before :each do
    @site = create_site_from_repo "www.retailer.com"
    Mocktra("www.retailer.com") do
      get '/products' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/products.html") do |file|
          file.read
        end
      end

      get '/1' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/1.html") do |file|
          file.read
        end
      end

      get '/2' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/2.html") do |file|
          file.read
        end
      end

      get '/4' do
        404
      end
    end
    @worker = ScrapePagesWorker.new
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "pops links from the LinkMessageQueue and pulls the page" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/1"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      WebMock.should have_requested(:get, "www.retailer.com/1")
      expect(WriteListingWorker.jobs.count).to eq(1)
    end

    it "correctly tags a 404 link" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/4"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker.jobs.count).to eq(1)
      job = WriteListingWorker.jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
    end

    it "correctly tags a not_found link in Redis" do
      pending "Example"
    end

    it "correctly tags an invalid link in Redis" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/4"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker.jobs.count).to eq(1)
      job = WriteListingWorker.jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_false
    end

    it "correctly tags a valid link in Redis" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/1"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker.jobs.count).to eq(1)
      job = WriteListingWorker.jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_true
      expect(msg.page_attributes["digest"]).to eq("b97637eba1fab547c75bd6ba372fb1ed")
    end

    it "sends a :dirty_only directive to WriteListingsWorker if the digest is unchanged" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      msg = LinkMessage.new(url: "http://#{@site.domain}/1")
      lq.add(msg)
      @worker.perform(domain: @site.domain)
      job = WriteListingWorker.jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_true
      expect(msg.page_attributes["digest"]).to eq("b97637eba1fab547c75bd6ba372fb1ed")
      WriteListingWorker.drain
      listing = Listing.all.first
      expect(listing.digest).to eq("b97637eba1fab547c75bd6ba372fb1ed")

      msg = LinkMessage.new(listing)
      lq.add(msg)
      ScrapePagesWorker.new.perform(domain: @site.domain)
      job = WriteListingWorker.jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.dirty_only?).to be_true
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source and does not add image_source to the ImageQueue" do
        url = "http://#{@site.domain}/1"
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        CDN::Image.create(source: image_source, http: PageUtils::HTTP.new)
        LinkMessageQueue.new(domain: @site.domain).add(LinkMessage.new(url: url))
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        iq = ImageQueue.new(domain: @site.domain)

        expect(msg.page_attributes["item_data"]["image_source"]).to eq(image_source)
        expect(msg.page_attributes["item_data"]["image"]).to eq("https://s3.amazonaws.com/scoperrific-index-test/c8f0568ee6c444af95044486351932fb.JPG")
        expect(iq.pop).to be_nil
      end
    end

    describe "where image_source does not exist on CDN already" do
      it "adds the image_source url to the ImageQueue and sets 'image' attribute to default" do
        url = "http://#{@site.domain}/1"
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        LinkMessageQueue.new(domain: @site.domain).add(LinkMessage.new(url: url))
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        iq = ImageQueue.new(domain: @site.domain)

        expect(msg.page_attributes["item_data"]["image_source"]).to eq(image_source)
        expect(msg.page_attributes["item_data"]["image"]).to eq(CDN::DEFAULT_IMAGE_URL)
        expect(iq.pop).to eq(image_source)
      end
    end
  end

  describe "#transition" do
    it "transitions to self if it times out while the site's LinkMessageQueue is not empty" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      links = (1..10).map { |i| LinkMessage.new(url: "http://www.retailer.com/#{i}") }
      lq.add links
      @worker.timeout = 5
      @worker.perform(domain: @site.domain)
      expect(lq.size).to eq(6)
      expect(ScrapePagesWorker.jobs.count).to eq(1)
    end

    it "transitions to RefreshLinksWorker if the site's LinkMessageQueue is empty and the site should be read again" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      links = (1..10).map { |i| LinkMessage.new(url: "http://www.retailer.com/#{i}") }
      lq.add links
      @site.update(read_interval: 0, read_at: 10.days.ago)
      @worker.perform(domain: @site.domain)
      expect(lq.size).to be_zero
      expect(RefreshLinksWorker.jobs.count).to eq(1)
    end

    it "does not transition to RefreshLinksWorker if the site's LinkMessageQueue is empty and the site should not be read again" do
      @site.update(read_interval: 100000)
      @worker.perform(domain: @site.domain)
      expect(RefreshLinksWorker.jobs.count).to be_zero
    end
  end
end
