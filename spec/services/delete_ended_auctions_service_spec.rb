require 'spec_helper'
require 'sidekiq/testing'

describe DeleteEndedAuctionsService do
  before :each do
    @service = DeleteEndedAuctionsService.new
  end

  describe "#run", no_es: true do
    it "generates DeleteListingsWorker jobs for batches of ended auctions" do
      Sidekiq::Testing.fake!
      5.times { FactoryGirl.create(:auction_listing) }
      auctions = []
      5.times { auctions << FactoryGirl.create(:auction_listing, :ended) }

      @service.track
      @service.start_jobs
      @service.stop_tracking

      expect(DeleteListingsWorker.jobs.count).to eq(1)
      job = DeleteListingsWorker.jobs.first
      job["args"].first.each do |id|
        expect(auctions.map(&:id)).to include(id)
      end
    end
  end
end
