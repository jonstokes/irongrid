require 'spec_helper'
require 'sidekiq/testing'

describe DeleteListingsForFullFeedsService do

  before :each do
    @service = DeleteListingsForFullFeedsService.new
    Stretched::ObjectQueue.new("ammo.net/listings").clear
    clear_sidekiq
  end

  describe "#run" do
    it "creates DeleteListingsWorker jobs for all listings older than site.read_at if listing OBQ is empty" do
      Sidekiq::Testing.fake!

      site = create_site "ammo.net"
      site.update(read_at: Time.now - 1.day)

      removed = []
      kept = []
      5.times { removed << FactoryGirl.create(:retail_listing, seller_domain: "ammo.net", updated_at: Time.now - 10.days) }
      sleep 1
      5.times { kept << FactoryGirl.create(:retail_listing, seller_domain: "ammo.net") }

      @service.start_jobs
      expect(DeleteListingsWorker.jobs.count).to eq(1)
      job = DeleteListingsWorker.jobs.first
      job["args"].first.each do |id|
        expect(removed.map(&:id)).to include(id)
        expect(kept.map(&:id)).not_to include(id)
      end
    end

    it "creates DeleteListingsWorker jobs for no listings older than site.read_at if listing OBQ is not empty" do
      Sidekiq::Testing.fake!

      object = {
        page: { url: "http://ammo.net/1" },
        session: {},
        object: {
          url: "http://ammo.net/1"
        }
      }
      Stretched::ObjectQueue.new("ammo.net/listings").add(object)

      site = create_site "ammo.net"
      site.update(read_at: Time.now - 1.day)

      5.times { FactoryGirl.create(:retail_listing, seller_domain: "ammo.net", updated_at: Time.now - 10.days) }
      5.times { FactoryGirl.create(:retail_listing, seller_domain: "ammo.net") }
      @service.start_jobs
      expect(DeleteListingsWorker.jobs.count).to be_zero
    end

  end
end
