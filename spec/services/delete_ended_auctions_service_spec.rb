require 'spec_helper'
require 'sidekiq/testing'

describe DeleteEndedAuctionsService do
  before :each do
    @service = DeleteEndedAuctionsService.new
  end

  it "generates DeleteEndedAuctionsWorker jobs for batches of ended auctions" do
    Sidekiq::Testing.fake!
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    5.times { auctions << FactoryGirl.create(:auction_listing, :ended) }

    @service.start_jobs
    expect(DeleteEndedAuctionsWorker.jobs.count).to eq(1)
    job = DeleteEndedAuctionsWorker.jobs.first
    job["args"].first.each do |id|
      expect(auctions.map(&:id)).to include(id)
    end
  end

  it "does not generate more DeleteEndedAuctionsWorkers if there are already workers enqueued" do
    Sidekiq::Testing.disable!
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    5.times { auctions << FactoryGirl.create(:auction_listing, :ended) }
    DeleteEndedAuctionsWorker.perform_async(auctions.map(&:id))
    @service.start_jobs
    expect(DeleteEndedAuctionsWorker.queued_jobs.count).to eq(1)
  end

end
