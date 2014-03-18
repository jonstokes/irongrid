require 'spec_helper'

describe RefreshLinksWorker do
  before :all do
    create_site_from_repo "www.retailer.com"
  end

  after :each do
    LinkSet.new(domain: "www.retailer.com").clear
  end

  it "adds linksto the LinkSet for stale listings" do
    5.times { FactoryGirl.create(:retail_listing, seller_domain: "www.retailer.com", updated_at: Time.now - 10.hours) }
    5.times { FactoryGirl.create(:retail_listing, seller_domain: "www.retailer.com", updated_at: Time.now) }
    RefreshLinksWorker.new.perform(domain: "www.retailer.com")
    ls = LinkSet.new(domain: "www.retailer.com")
    ls.size.should == 5
    link = ls.pop
    expect(link).to match(/retailer\.com/)
  end
end
