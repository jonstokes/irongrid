require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.disable!

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
    @service.start
    @service.stop
    workers = Sidekiq::Workers.new

    expect(DeleteEndedAuctionsWorker.queued_jobs.count).to eq(1)
    workers.each do |name, work, started_at|
      expect(work['queue']).to eq('fast_db')
      expect(work['payload']).to eq('foo')
    end
  end
end
