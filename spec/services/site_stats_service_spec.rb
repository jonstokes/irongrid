require 'spec_helper'
require 'sidekiq/testing'

describe SiteStatsService do
  before :each do
    Sidekiq::Testing.fake!
  end

  describe "#run", no_es: true do
    it "generates a SiteStatsWorker for each active site" do
      create_site "www.retailer.com"
      create_site "www.budsgunshop.com"
      service = SiteStatsService.new
      service.start
      service.stop
      expect(SiteStatsWorker.jobs.count).to eq(2)
    end
  end
end
