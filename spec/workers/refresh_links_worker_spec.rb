require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe RefreshLinksWorker do
  before :each do
    @site = create_site_from_repo "www.retailer.com"
    LinkMessageQueue.new(domain: "www.retailer.com").clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "adds links to the LinkMessageQueue for stale listings" do
      stale_listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days)
      5.times { FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days) }
      FactoryGirl.create(:retail_listing, updated_at: Time.now)
      RefreshLinksWorker.new.perform(domain: @site.domain)
      msg = LinkMessageQueue.find(stale_listing.url)
      expect(msg.listing_id).to eq(stale_listing.id)
      expect(msg.listing_digest).to eq(stale_listing.digest)

      lq = LinkMessageQueue.new(domain: "www.retailer.com")
      lq.size.should == 6
      expect(lq.pop.url).to match(/retailer\.com/)
      expect(CreateLinksWorker.jobs.count).to eq(1)
      expect(LogRecordWorker.jobs.count).to eq(2)
    end

    it "exits early if the site is being read by another worker" do
      Sidekiq::Testing.disable!
      ScrapePagesWorker.perform_async(domain: @site.domain)
      5.times { FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days) }
      RefreshLinksWorker.new.perform(domain: @site.domain)
      expect(LinkMessageQueue.new(domain: @site.domain).size).to eq(0)
      Sidekiq::Testing.fake!
    end
  end

  describe "#transition" do
    it "transitions to CreateLinksWorker without blowing up if there are no stale listings" do
      5.times { FactoryGirl.create(:retail_listing) }
      expect {
        RefreshLinksWorker.new.perform(domain: @site.domain)
      }.not_to raise_error
      expect(CreateLinksWorker.jobs.count).to eq(1)
      expect(ScrapePagesWorker.jobs.count).to eq(0)
      expect(LogRecordWorker.jobs.count).to eq(2)
    end

    it "transitions to ScrapePagesWorker if the site is refresh_only" do
      @site.site_data[:service_options].merge!('refresh_only' => true)
      @site.send(:write_to_redis)
      5.times { FactoryGirl.create(:retail_listing) }
      expect {
        RefreshLinksWorker.new.perform(domain: @site.domain)
      }.not_to raise_error
      expect(CreateLinksWorker.jobs.count).to eq(0)
      expect(ScrapePagesWorker.jobs.count).to eq(1)
      expect(LogRecordWorker.jobs.count).to eq(2)
    end
  end
end
