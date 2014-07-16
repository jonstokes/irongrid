require 'spec_helper'
require 'webmock/rspec'
require 'mocktra'
require 'sidekiq/testing'

describe ScrapePagesWorker do
  before :each do
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.retailer.com"
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
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
    it "should exit early if it's not along with this domain" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/1"
      lq.add(LinkMessage.new(url: url))
      ScrapePagesWorker.perform_async(domain: @site.domain)
      @worker.perform(domain: @site.domain)
      WebMock.should_not have_requested(:get, "www.retailer.com/1")
      expect(WriteListingWorker._jobs.count).to eq(0)
    end

    it "pops links from the LinkMessageQueue and pulls the page" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/1"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      WebMock.should have_requested(:get, "www.retailer.com/1")
      expect(WriteListingWorker._jobs.count).to eq(1)
    end

    it "correctly tags a 404 link" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/4"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
    end

    it "correctly tags a classified_sold link in redis" do
      pending "Example"
    end

    it "correctly tags a not_found link in redis" do
      pending "Example"
    end

    it "correctly tags an invalid link in redis" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/4"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_false
    end

    it "correctly tags a valid link in redis" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      url = "http://#{@site.domain}/1"
      lq.add(LinkMessage.new(url: url))
      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_true
      expect(msg.page_attributes["digest"]).to eq("0d44f30c1c686ad62728ee7952a99d04")
    end

    it "sends a :dirty_only directive to WriteListingsWorker if the digest is unchanged" do
      Sidekiq::Testing.fake! do
        lq = LinkMessageQueue.new(domain: @site.domain)
        msg = LinkMessage.new(url: "http://#{@site.domain}/1")
        lq.add(msg)
        @worker.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_attributes["digest"]).to eq("0d44f30c1c686ad62728ee7952a99d04")
        WriteListingWorker.drain
        listing = Listing.all.first
        expect(listing.digest).to eq("0d44f30c1c686ad62728ee7952a99d04")

        msg = LinkMessage.new(listing)
        lq.add(msg)
        ScrapePagesWorker.new.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.dirty_only?).to be_true
      end
    end

    it "marks as not_found any link for a site with no page_adapter" do
      site = create_site "ammo.net", source: :local
      lq = LinkMessageQueue.new(domain: site.domain)
      msg = LinkMessage.new(url: "http://#{site.domain}/1")
      lq.add(msg)
      @worker.perform(domain: site.domain)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source and does not add image_source to the ImageQueue" do
        url = "http://#{@site.domain}/1"
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        CDN::Image.create(source: image_source, http: PageUtils::HTTP.new)
        LinkMessageQueue.new(domain: @site.domain).add(LinkMessage.new(url: url))
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
        url = "http://#{@site.domain}/1"
        image_source = "http://www.emf-company.com/store/pc/catalog/1911CITCSPHBat10MED.JPG"
        LinkMessageQueue.new(domain: @site.domain).add(LinkMessage.new(url: url))
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
    it "transitions to self if it times out while the site's LinkMessageQueue is not empty" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      links = (1..10).map { |i| LinkMessage.new(url: "http://www.retailer.com/#{i}") }
      lq.add links
      @worker.perform(domain: @site.domain, timeout: 5)
      expect(lq.size).not_to be_zero
      expect(ScrapePagesWorker._jobs.count).to eq(1)
    end

    it "transitions to RefreshLinksWorker if the site's LinkMessageQueue is empty and the site should be read again" do
      lq = LinkMessageQueue.new(domain: @site.domain)
      links = (1..10).map { |i| LinkMessage.new(url: "http://www.retailer.com/#{i}") }
      lq.add links
      @site.update(read_interval: 0, read_at: 10.days.ago)
      @worker.perform(domain: @site.domain)
      expect(lq.size).to be_zero
      expect(RefreshLinksWorker._jobs.count).to eq(1)
    end

    it "does not transition to RefreshLinksWorker if the site's LinkMessageQueue is empty and the site should not be read again" do
      @site.update(read_interval: 100000)
      @worker.perform(domain: @site.domain)
      expect(RefreshLinksWorker._jobs.count).to be_zero
    end
  end
end
