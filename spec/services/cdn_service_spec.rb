require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.disable!


describe CdnService do
  before :each do
    Sidekiq.redis do |conn|
      conn.flushdb
    end
    @service = CdnService.new
    @site = create_site_from_repo "www.retailer.com"
    @iq = ImageQueue.new(domain: @site.domain)
    @iq.clear
  end

  it "should use DMS" do
    pending "Example"
  end

  describe "#run" do
    it "generates a CreateCdnImagesWorker for a site with a non-empty ImageQueue" do
      5.times { |i| @iq.push "http://www.retailer.com/images/#{i}.png" }
      CreateCdnImagesWorker.perform_async(domain: "www.foo.com")
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it "does not generates a CreateCdnImagesWorker for a site that already has images being read" do
      5.times { |i| @iq.push "http://www.retailer.com/images/#{i}.png" }
      CreateCdnImagesWorker.perform_async(domain: @site.domain)
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it "does not generate a CreateCdnImagesWorker for a site with an empty ImageQueue" do
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end
end
