require 'spec_helper'
require 'sidekiq/testing'

describe ObjectQueueWorker do
  before :each do
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.retailer.com"
    @worker = ObjectQueueWorker.new
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
    it "pops 100 objects from the object queue for Listing" do
      pending "Example"
      # populate object_q(Listing)

      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
    end

    it "correctly tags a 404 link" do
      pending "Example"
      # populate obq with { page: { code: 404 } }

      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
    end

    it "correctly tags a not_found link in redis" do
      pending "Example"
      # populate obq with not_found

      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_not_found?).to be_true
    end

    it "correctly tags an invalid link in redis" do
      pending "Example"
      # populate obq with valid: false object

      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_false
    end

    it "correctly tags a valid link in redis" do
      pending "Example"
      # populate obq with valid: true obj

      @worker.perform(domain: @site.domain)
      expect(WriteListingWorker._jobs.count).to eq(1)
      job = WriteListingWorker._jobs.first
      msg = LinkMessage.new(job["args"].first)
      expect(msg.page_is_valid?).to be_true
      expect(msg.page_attributes["digest"]).to eq("0d44f30c1c686ad62728ee7952a99d04")
    end

    it "sends a :dirty_only directive to WriteListingsWorker if the digest is unchanged" do
      pending "Example"
      Sidekiq::Testing.fake! do
        # populate obq with obj1

        @worker.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_attributes["digest"]).to eq("0d44f30c1c686ad62728ee7952a99d04")

        WriteListingWorker.drain

        listing = Listing.all.first
        expect(listing.digest).to eq("0d44f30c1c686ad62728ee7952a99d04")

        # populate obq with obj1
        ObjectQueueWorker.new.perform(domain: @site.domain)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.dirty_only?).to be_true
      end
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source and does not add image_source to the ImageQueue" do
        pending "Example"
        # populate obq with object
        # populate CDN with object.image

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
        pending "Example"
        # populate obq with object
        #
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
end
