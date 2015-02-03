require 'spec_helper'
require 'sidekiq/testing'

describe ReadSitesService do
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

  describe "PopulateSessionQueue sites", no_es: true do
    before :each do
      @site = create_site "www.retailer.com"
      @service = ReadSitesService.new
    end

    it "should generate a PopulateSessionQueue for a site if it should be read" do
      @site.update(read_at: 10.days.ago)
      @service.start
      @service.stop
      expect(PopulateSessionQueueWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end

    it "should not generate a PopulateSessionQueue for a site if it was recently read" do
      @site.update(read_at: Time.now)
      @service.start
      @service.stop
      expect(PopulateSessionQueueWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end

    it "should not generate a PopulateSessionQueue for a site if the site has sessions pending" do
      pending "Populate session queue with sessions for site"
      expect(true).to eq(false)

      @service.start
      @service.stop
      expect(PopulateSessionQueueWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end

    it "should not generate a PopulateSessionQueue for a site if the site has product links pending" do
      pending "Populate session queue with sessions for site"
      expect(true).to eq(false)

      @service.start
      @service.stop
      expect(PopulateSessionQueueWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end
end
