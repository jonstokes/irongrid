require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.disable!


describe ReadSitesService do
  before :each do
    Sidekiq.redis do |conn|
      conn.flushdb
    end
  end

  it "should use DMS" do
    pending "Example"
  end

  describe "RefreshLinksWorker sites" do
    before :each do
      @site = create_site_from_repo "www.retailer.com"
      @site.update(read_with: "RefreshLinksWorker")
      @service = ReadSitesService.new
      @lq = LinkQueue.new(domain: @site.domain)
      @lq.clear
    end

    it "should generate a RefreshLinksWorker for a site if its LinkQueue is empty and it should be read" do
      @site.update(read_at: 10.days.ago)
      @service.start
      @service.stop
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end

    it "should not generate a RefreshLinksWorker for a site if its LinkQueue should not be read" do
      @site.update(read_at: Time.now)
      @service.start
      @service.stop
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end

    it "should not generate a RefreshLinksWorker for a site if its LinkQueue is not empty" do
      5.times { |i| @lq.push "http://#{@site.domain}/#{i + 10}" }
      @site.update(read_at: 10.days.ago)
      @service.start
      @service.stop
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end

  describe "CreateLinksWorker sites" do
    before :each do
      @site = create_site_from_repo "www.retailer.com"
      @site.update(read_with: "CreateLinksWorker")
      @service = ReadSitesService.new
      @lq = LinkQueue.new(domain: @site.domain)
      @lq.clear
    end

    it "should read a CreateLinksWorker site if its LinkQueue is empty and it should be read" do
      @site.update(read_at: 10.days.ago)
      @service.start
      @service.stop
      expect(CreateLinksWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end

    it "should not read a CreateLinksWorker site if its LinkQueue is not empty" do
      5.times { |i| @lq.push "http://#{@site.domain}/#{i + 10}" }
      @site.update(read_at: 10.days.ago)
      @service.start
      @service.stop
      expect(CreateLinksWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty
    end
  end

  describe "AvantlinkWorker and RssWorker sites" do
    before :each do
      @site = create_site_from_repo "www.retailer.com"
      @service = ReadSitesService.new
      @lq = LinkQueue.new(domain: @site.domain)
      @lq.clear
    end

    it "should read an AvantlinkWorker site with the correct worker" do
      @site.update(read_at: 10.days.ago)
      @site.update(read_with: "AvantlinkWorker")
      @service.start
      @service.stop
      expect(AvantlinkWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end

    it "should read an RssWorker site with the correct worker" do
      @site.update(read_at: 10.days.ago)
      @site.update(read_with: "RssWorker")
      @service.start
      @service.stop
      expect(RssWorker.jobs_in_flight_with_domain(@site.domain).size).to eq(1)
    end
  end
end
