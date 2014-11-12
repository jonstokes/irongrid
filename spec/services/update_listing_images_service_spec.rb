require 'spec_helper'
require 'sidekiq/testing'

describe UpdateListingImagesService do
  before :each do
    Sidekiq::Testing.fake!
    @service = UpdateListingImagesService.new
  end

  describe "#run", no_es: true do
    it "generates UpdateListingImagesWorker jobs for batches of recently updated listings with no image" do
      listings = []
      5.times { listings << create(:listing, :no_image) }
      IronBase::Listing.refresh_index

      @service.track
      @service.start_jobs
      @service.stop_tracking
      expect(UpdateListingImagesWorker.jobs.count).to eq(1)
      job = UpdateListingImagesWorker.jobs.first
      job["args"].first.each do |id|
        expect(listings.map(&:id)).to include(id)
      end
    end
  end
end
