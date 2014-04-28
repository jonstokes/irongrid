require 'spec_helper'

describe SiteStatsWorker do
  describe "#perform" do
    it "generates site stats for a site" do
      site = create_site "www.retailer.com"
      FactoryGirl.create(:retail_listing)
      stalest = FactoryGirl.create(:retail_listing, updated_at: Time.now - 10.days)
      FactoryGirl.create(:retail_listing, :inactive)

      worker = SiteStatsWorker.new
      worker.perform(domain: site.domain)

      s = Site.new(domain: site.domain, source: :redis)
      expect(s.site_data[:stats][:active_listings]).to eq(2)
      expect(s.site_data[:stats][:inactive_listings]).to eq(1)
      expect(s.site_data[:stats][:stalest_listing]).to eq(stalest.id)
      expect(s.site_data[:stats][:updated_at]).to be_a(Time)

    end
  end
end
