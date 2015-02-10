require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.disable!

describe CdnService do
  before :each do
    Sidekiq::Testing.disable!
    clear_sidekiq
    @service = CdnService.new
    @site = create_site "www.retailer.com"
    @site.image_queue.clear
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  it "should use DMS", no_es: true do
    pending "Example"
    expect(true).to eq(false)
  end

  describe "#run", no_es: true do
    it "generates a CreateCdnImagesWorker for a site with a non-empty IronCore::ImageQueue" do
      5.times { |i| @site.image_queue.push "http://www.retailer.com/images/#{i}.png" }
      CreateCdnImagesWorker.perform_async(domain: "www.foo.com")
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain("www.foo.com").count).to eq(1)
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it "does not generates a CreateCdnImagesWorker for a site that already has images being read" do
      5.times { |i| @site.image_queue.push "http://www.retailer.com/images/#{i}.png" }
      CreateCdnImagesWorker.perform_async(domain: @site.domain)
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it "does not generate a CreateCdnImagesWorker for a site with an empty IronCore::ImageQueue" do
      @service.start
      @service.stop
      expect(CreateCdnImagesWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end
end
