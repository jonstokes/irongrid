require 'spec_helper'
require 'sidekiq/testing'

describe PruneLinksWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.retailer.com"
    @worker = PruneLinksWorker.new
    @lq = LinkMessageQueue.new(domain: @site.domain)
    @lq.clear
    Sidekiq::Worker.clear_all
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do
    it "should remove a link from the LinkMessageQueue if it's fresh, and leave it if it's stale" do
      fresh_listing = nil
      msg = nil
      5.times do |i|
        fresh_listing = FactoryGirl.create(:retail_listing)
        @lq.push LinkMessage.new(url: fresh_listing.url, jid: "abcd123")
        @lq.push LinkMessage.new(url: "http://#{@site.domain}/#{i + 100}", jid: "abcd123")
      end

      stale_listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days)
      msg = LinkMessage.new(url: stale_listing.url, jid: "abcd123")
      @lq.push msg
      @worker.perform(domain: @site.domain)
      expect(@lq.has_key?(stale_listing.url)).to be_true
      expect(@lq.has_key?(fresh_listing.url)).to be_false
      expect(@lq.size).to eq(6)
    end

    it "exits early if the site is being read by another worker" do
    end

  end

  describe "#transition" do
    it "transitions to RefreshLinksWorker if there are any links" do
      listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days)
      @lq.push LinkMessage.new(url: listing.url, jid: "abcd123")
      @worker.perform(domain: @site.domain)
      expect(@lq.size).to eq(1)
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it "does not transition to RefreshLinksWorker if there are no links" do
      listing = FactoryGirl.create(:retail_listing)
      @lq.push LinkMessage.new(url: listing.url, jid: "abcd123")
      @worker.perform(domain: @site.domain)
      expect(@lq.size).to eq(0)
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(0)
    end
  end
end
