require 'spec_helper'

describe SiteStatsWorker do
  describe "#perform" do
    it "generates site stats for a site" do
      site = create_site "www.retailer.com"
      create(:listing)
      stalest = FactoryGirl.create(:listing, updated_at: Time.now - 10.days)
      create(:listing, :inactive)
      IronBase::Listing.refresh_index

      worker = SiteStatsWorker.new
      worker.perform(domain: site.domain)

      s = Site.new(domain: site.domain, source: :redis)
      expect(s.site_data[:stats][:inactive_listings]).to eq(1)
      expect(s.site_data[:stats][:active_listings]).to eq(2)
      expect(s.site_data[:stats][:stalest_listing].strftime("%Y-%m-%dT%H:%M:%S")).to eq(stalest.updated_at.strftime("%Y-%m-%dT%H:%M:%S"))
      expect(s.site_data[:stats][:updated_at]).to be_a(Time)

    end
  end
end
