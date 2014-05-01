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
      5.times { listings << FactoryGirl.create(:retail_listing, :no_image) }

      @service.start_jobs
      expect(UpdateListingImagesWorker.jobs.count).to eq(1)
      job = UpdateListingImagesWorker.jobs.first
      job["args"].first.each do |id|
        expect(listings.map(&:id)).to include(id)
      end
    end
  end
end
