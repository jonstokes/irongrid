require 'spec_helper'
require 'sidekiq/testing'

describe ReadListingsService do
  before :each do
    Sidekiq::Testing.disable!
    clear_sidekiq
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  it "should use DMS" do
    pending "Example"
    expect(true).to eq(false)
  end

  describe "PullListingsWorker sites", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
      @q = Stretched::ObjectQueue.new("#{@site.domain}/listings")
      @q.clear
      @service = ReadListingsService.new
      @objects = (1..3).map do |i|
        {
          url: "http://www.retailer.com/#{i}"
        }
      end
    end

    it "generates a PullListingsWorker for a site if it has listings in its object queue" do
      @q.add @objects
      @service.start
      @service.stop
      expect(PullListingsWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end

    it "does not generate a PullListingsWorker for a site if does not have listings in its object queue" do
      @service.start
      @service.stop
      expect(PullListingsWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end
end
