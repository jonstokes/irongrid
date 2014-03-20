require 'spec_helper'

describe RefreshLinksWorker do
  before :all do
    @site = create_site_from_repo "www.retailer.com"
  end

  after :each do
    LinkSet.new(domain: "www.retailer.com").clear
  end

  describe "#perform" do
    it "adds linksto the LinkSet for stale listings" do
      FactoryGirl.create(:retail_listing, site_id: @site.id, updated_at: Time.now - 10.hours)
      FactoryGirl.create(:retail_listing, site_id: @site.id, updated_at: Time.now)
      RefreshLinksWorker.new.perform(domain: "www.retailer.com")
      ls = LinkSet.new(domain: "www.retailer.com")
      ls.size.should == 1
      link = ls.pop
      expect(link).to match(/retailer\.com/)
      expect(CreateLinksWorker.jobs.count).to eq(1)
    end

    it "does not transition to next state if the LinkSet is empty" do
      FactoryGirl.create(:retail_listing, site_id: @site.id, updated_at: Time.now)
      RefreshLinksWorker.new.perform(domain: "www.retailer.com")
      ls = LinkSet.new(domain: "www.retailer.com")
      ls.size.should == 0
      expect(CreateLinksWorker.jobs.count).to eq(0)
    end

  end
end
