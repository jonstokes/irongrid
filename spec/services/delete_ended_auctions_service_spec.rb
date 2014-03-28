require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe DeleteEndedAuctionsService do
  before :each do
    @service = DeleteEndedAuctionsService.new
    Sidekiq.redis do |conn|
      conn.flushdb
    end
  end

  it "generates DeleteEndedAuctionsWorker jobs for batches of ended auctions" do
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    5.times { auctions << FactoryGirl.create(:auction_listing, :ended) }
    puts "Spec found #{Listing.ended_auctions.count} ended auctions"

    @service.start_jobs
    expect(DeleteEndedAuctionsWorker.jobs.count).to eq(1)
    job = DeleteEndedAuctionsWorker.jobs.first
    job["args"].first.each do |id|
      expect(auctions.map(&:id)).to include(id)
    end
  end
end
