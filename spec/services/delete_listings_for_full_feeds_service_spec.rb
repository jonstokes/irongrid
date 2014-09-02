require 'spec_helper'
require 'sidekiq/testing'

describe DeleteListingsForFullFeedsService do

  before :each do
    Sidekiq::Testing.disable!
    clear_sidekiq
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#run" do
    it "creates DeleteListingsWorker jobs for all listings older than site.read_at if listing OBQ is empty" do
      pending "Example"
      # create listings that are older than site.read_at
      # create listings that are newer than site.read_at
      # clear OBQ
      @worker.perform(domain: @site.domain)
      # expect Listing.count to eq number of newer listings created above

    end

    it "creates DeleteListingsWorker jobs for no listings older than site.read_at if listing OBQ is not empty" do
      pending "Example"
      # create listings that are older than site.read_at
      # create listings that are newer than site.read_at
      # populate OBQ
      @worker.perform(domain: @site.domain)
      # expect Listing.count to eq total number of listings created above
    end

  end
end
