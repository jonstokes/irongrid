require 'spec_helper'
include SidekiqUtils

describe RefreshLinksWorker do
  before :all do
    @site = create_site_from_repo "www.retailer.com"
  end

  after :each do
    LinkSet.new(domain: "www.retailer.com").clear
  end

  describe "#perform" do
    it "adds links to the LinkSet for stale listings" do
      listing = FactoryGirl.create(:retail_listing, site_id: @site.id, updated_at: Time.now - 10.hours)
      FactoryGirl.create(:retail_listing, site_id: @site.id, updated_at: Time.now)
      RefreshLinksWorker.new.perform(domain: "www.retailer.com")
      ls = LinkSet.new(domain: "www.retailer.com")
      ls.size.should == 1
      link = ls.pop
      expect(link[:url]).to match(/retailer\.com/)
      expect(link[:id]).to eq(listing.id)
      expect(CreateLinksWorker.jobs.count).to eq(1)
    end
  end
end
