require 'spec_helper'
require 'sidekiq/testing'

describe DeleteListingsForFullFeedsService do

  before :each do
    @service = DeleteListingsForFullFeedsService.new
    @site = create_site "ammo.net"
    @site.session_queue.clear
    @site.listings_queue.clear
    clear_sidekiq
  end

  describe "#run" do
    it 'creates DeleteListingsWorker jobs for all listings older than site.read_at if listing OBQ is empty' do
      Sidekiq::Testing.fake!

      @site.update(read_at: Time.now - 1.day)
      removed = []
      kept = []
      5.times do
        removed << create(:listing, seller: { domain: "ammo.net" }, updated_at: Time.now - 10.days)
      end
      sleep 1
      5.times { kept << create(:listing, seller: { domain: "ammo.net" }) }
      IronBase::Listing.refresh_index

      @service.track
      @service.start_jobs
      @service.stop_tracking

      expect(DeleteListingsWorker.jobs.count).to eq(1)
      job = DeleteListingsWorker.jobs.first
      job["args"].first.each do |id|
        expect(removed.map(&:id)).to include(id)
        expect(kept.map(&:id)).not_to include(id)
      end
    end

    it 'creates no DeleteListingsWorker jobs for all listings older than 1 day ago if site.read_at is nil' do
      Sidekiq::Testing.fake!

      @site = create_site "ammo.net"
      @site.update(read_at: nil)

      removed = []
      kept = []
      5.times do
        removed << create(:listing, seller: { domain: "ammo.net" }, updated_at: Time.now - 10.days)
      end
      sleep 1
      5.times { kept << create(:listing, seller: { domain: "ammo.net" }) }
      IronBase::Listing.refresh_index

      @service.track
      @service.start_jobs
      @service.stop_tracking

      expect(DeleteListingsWorker.jobs.count).to be_zero
    end


    it 'creates DeleteListingsWorker jobs for no listings older than site.read_at if listing OBQ is not empty' do
      Sidekiq::Testing.fake!

      object = {
        page: { url: "http://ammo.net/1" },
        session: {},
        object: {
          url: "http://ammo.net/1"
        }
      }
      @site.listings_queue.add(object)
      @site.update(read_at: Time.now - 1.day)

      5.times do
        create(:listing, seller: { domain: "ammo.net" }, updated_at: Time.now - 10.days)
      end
      sleep 1
      5.times { create(:listing, seller: { domain: "ammo.net" }) }
      IronBase::Listing.refresh_index
      @service.track
      @service.start_jobs
      @service.stop_tracking

      expect(DeleteListingsWorker.jobs.count).to be_zero
    end

  end
end
