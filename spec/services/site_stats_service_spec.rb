require 'spec_helper'
require 'sidekiq/testing'

describe SiteStatsService do
  describe "#perform" do
    it "generates a SiteStatsWorker for each active site" do
      create_site_from_repo "www.retailer.com"
      create_site_from_repo "www.budsgunshop.com"
      service = SiteStatsService.new
      service.start
      service.stop
      expect(SiteStatsWorker.jobs.count).to eq(2)
    end
  end
end
