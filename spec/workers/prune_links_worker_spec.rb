require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe PruneLinksWorker do
  before :each do
    @site = create_site_from_repo "www.retailer.com"
    @worker = PruneLinksWorker.new
    @lq = LinkMessageQueue.new(domain: @site.domain)
    @lq.clear
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "should remove a link from the LinkMessageQueue if it's fresh, and leave it if it's stale" do
      fresh_listing = nil
      ld = nil
      5.times do |i|
        fresh_listing = FactoryGirl.create(:retail_listing)
        LinkData.create(url: fresh_listing.url, jid: "abcd123")
        @lq.push fresh_listing.url

        ld = LinkData.create(url: "http://#{@site.domain}/#{i + 100}", jid: "abcd123")
        @lq.push ld.url
      end

      stale_listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days)
      LinkData.create(url: stale_listing.url, jid: "abcd123")
      @lq.push stale_listing.url
      @worker.perform(domain: @site.domain)
      expect(@lq.has_key?(stale_listing.url)).to be_true
      expect(LinkData.find(stale_listing.url)).not_to be_nil
      expect(@lq.has_key?(ld.url)).to be_true
      expect(LinkData.find(ld.url)).not_to be_nil
      expect(@lq.has_key?(fresh_listing.url)).to be_false
      expect(LinkData.find(ld.url)).not_to be_nil
      expect(@lq.size).to eq(6)
    end

    it "exits early if the site is being read by another worker" do
    end

  end

  describe "#transition" do
    it "transitions to ScrapePagesWorker if there are any links" do
      listing = FactoryGirl.create(:retail_listing, updated_at: Time.now - 5.days)
      LinkData.create(url: listing.url, jid: "abcd123")
      @lq.push listing.url
      @worker.perform(domain: @site.domain)
      expect(@lq.size).to eq(1)
      expect(ScrapePagesWorker.jobs.count).to eq(1)
    end

    it "does not transition to ScrapePagesWorker if there are no links" do
      listing = FactoryGirl.create(:retail_listing)
      LinkData.create(url: listing.url, jid: "abcd123")
      @lq.push listing.url
      @worker.perform(domain: @site.domain)
      expect(@lq.size).to eq(0)
      expect(ScrapePagesWorker.jobs.count).to eq(0)
    end
  end
end
