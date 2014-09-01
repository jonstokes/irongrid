require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'

describe RefreshLinksWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.retailer.com"
    LinkMessageQueue.new(domain: "www.retailer.com").clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
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
    end
  end

  describe "#transition" do
    it "transitions to PushProductLinksWorker" do
      5.times { FactoryGirl.create(:retail_listing) }
      expect {
        RefreshLinksWorker.new.perform(domain: @site.domain)
      }.not_to raise_error
      expect(PushProductLinksWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end
  end
end
