require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe RefreshLinksWorker do
  before :all do
    @site = create_site_from_repo "www.retailer.com"
  end

  before :each do
    LinkQueue.new(domain: "www.retailer.com").clear
    LinkData.delete_all
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "adds links to the LinkQueue for stale listings" do
      listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 10.hours)
      FactoryGirl.create(:retail_listing, updated_at: Time.now)
      RefreshLinksWorker.new.perform(domain: "www.retailer.com")
      ld = LinkData.find(listing.url)
      expect(ld.listing_id).to eq(listing.id)
      expect(ld.listing_digest).to eq(listing.digest)

      lq = LinkQueue.new(domain: "www.retailer.com")
      lq.size.should == 1
      expect(lq.pop).to match(/retailer\.com/)
      expect(CreateLinksWorker.jobs.count).to eq(1)
    end
  end
end
