require 'spec_helper'
require 'sidekiq/testing'

describe PruneLinksWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.retailer.com"
    @worker = PruneLinksWorker.new
    @site.link_message_queue.clear
    Sidekiq::Worker.clear_all
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    it "should remove a link from the IronCore::LinkMessageQueue if it's fresh, and leave it if it's stale" do
      stale_listing = create(:listing, updated_at: Time.now - 5.days, seller: { domain: @site.domain })
      puts "## Stale url: #{stale_listing.url.page}"
      @site.link_message_queue.push IronCore::LinkMessage.new(url: stale_listing.url.page, jid: "abcd123")

      fresh_listings = []
      5.times do
        fresh_listings << create(:listing, seller: { domain: @site.domain })
      end

      messages = fresh_listings.map do |listing|
        puts "## Fresh url: #{listing.url.page}"
        IronCore::LinkMessage.new(url: listing.url.page, jid: "abcd123")
      end
      @site.link_message_queue.push messages

      IronBase::Listing.refresh_index
      @worker.perform(domain: @site.domain)

      expect(@site.link_message_queue.size).to eq(1)
      expect(@site.link_message_queue.has_key?(stale_listing.url.page)).to eq(true)
      fresh_listings.each do |listing|
        expect(@site.link_message_queue.has_key?(listing.url.page)).to eq(false)
      end
    end

    it 'exits early if the site is still being read' do
      PopulateSessionQueueWorker.new.perform(domain: @site.domain)
      fresh_listing = nil

      5.times do |i|
        fresh_listing = create(:listing, seller: { domain: @site.domain })
        @site.link_message_queue.push IronCore::LinkMessage.new(url: fresh_listing.url.page, jid: "abcd123")
      end
      stale_listing = create(:listing, updated_at: Time.now - 5.days, seller: { domain: @site.domain })
      IronBase::Listing.refresh_index
      msg = IronCore::LinkMessage.new(url: stale_listing.url.page, jid: "abcd123")
      @site.link_message_queue.push msg
      @worker.perform(domain: @site.domain)

      expect(@site.link_message_queue.has_key?(stale_listing.url.page)).to eq(true)
      expect(@site.link_message_queue.has_key?(fresh_listing.url.page)).to eq(true)
      expect(@site.link_message_queue.size).to eq(6)
    end

    it 'exits early if there are still product links in the queue for the site' do
      object = {
        page: { url: "http://#{@site.domain}/1" },
        object: { product_link: "http://#{@site.domain}/1" },
        session: {}
      }
      @site.product_links_queue.add(object)

      fresh_listing = nil
      5.times do |i|
        fresh_listing = create(:listing, seller: { domain: @site.domain })
        @site.link_message_queue.push IronCore::LinkMessage.new(url: fresh_listing.url.page, jid: "abcd123")
      end
      stale_listing = create(:listing, updated_at: Time.now - 5.days, seller: { domain: @site.domain })
      IronBase::Listing.refresh_index
      msg = IronCore::LinkMessage.new(url: stale_listing.url.page, jid: "abcd123")
      @site.link_message_queue.push msg
      @worker.perform(domain: @site.domain)

      expect(@site.link_message_queue.has_key?(stale_listing.url.page)).to eq(true)
      expect(@site.link_message_queue.has_key?(fresh_listing.url.page)).to eq(true)
      expect(@site.link_message_queue.size).to eq(6)
    end
  end

  describe '#transition' do
    it 'transitions to RefreshLinksWorker if there are any links' do
      stale = FactoryGirl.create(:listing, updated_at: Time.now - 5.days)
      IronBase::Listing.refresh_index
      @site.link_message_queue.push IronCore::LinkMessage.new(url: stale.url.page, jid: "abcd123")
      @worker.perform(domain: @site.domain)
      expect(@site.link_message_queue.size).to eq(1)
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end

    it 'transitions to RefreshLinksWorker even if there are no links' do
      fresh = FactoryGirl.create(:listing, seller: { domain: @site.domain })
      IronBase::Listing.refresh_index
      @site.link_message_queue.push IronCore::LinkMessage.new(url: fresh.url.page, jid: "abcd123")
      @worker.perform(domain: @site.domain)
      expect(@site.link_message_queue.size).to eq(0)
      expect(RefreshLinksWorker.jobs_in_flight_with_domain(@site.domain).count).to eq(1)
    end
  end
end
