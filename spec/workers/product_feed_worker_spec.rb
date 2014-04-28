require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe ProductFeedWorker do
  describe "#perform" do
    describe "Write to listings table from generic ammo feed" do
      before :each do
        @site = create_site "ammo.net"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear
        CDN.clear!
        Sidekiq::Worker.clear_all
      end

      it "should create WriteListingWorkers for new listings with proper payload" do
        Mocktra(@site.domain) do
          get '/media/feeds/genericammofeed.xml' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(18)
        expect(LogRecordWorker.jobs.count).to eq(2)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.url).to match(/ammo\.net/)
        expect(msg.page_attributes["digest"]).not_to be_nil
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_not_found?).to be_false
      end

      it "should create WriteListingWorkers for modified listings with proper payload" do
        Mocktra(@site.domain) do
          get '/media/feeds/genericammofeed.xml' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed_updates.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(18)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.url).to match(/ammo\.net/)
        expect(msg.page_attributes["digest"]).not_to be_nil
        expect(msg.page_attributes["item_data"]["price_in_cents"]).to eq(1150)
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_not_found?).to be_false
      end

      it "should add a link to the ImageQueue for each new or updated listing" do
        Mocktra(@site.domain) do
          get '/media/feeds/genericammofeed.xml' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        iq = ImageQueue.new(domain: @site.domain)
        expect(iq.size).to eq(18)
        expect(iq.pop).to match(/cloudfront\.net/)
      end
    end

    describe "Write to listings table from Avanlink feed" do
      before :each do
        @site = create_site "www.brownells.com"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear
        CDN.clear!
        Sidekiq::Worker.clear_all
      end

      it "should create WriteListingWorkers for new listings with proper payload" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(4)
        expect(LogRecordWorker.jobs.count).to eq(2)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.url).to match(/avantlink\.com/)
        expect(msg.page_attributes["digest"]).not_to be_nil
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_not_found?).to be_false
      end

      it "should create WriteListingWorkers for modified listings with proper payload" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed_update.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(4)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.url).to match(/avantlink\.com/)
        expect(msg.page_attributes["digest"]).not_to be_nil
        expect(msg.page_attributes["item_data"]["price_in_cents"]).to eq(109)
        expect(msg.page_is_valid?).to be_true
        expect(msg.page_not_found?).to be_false
      end

      it "should create WriteListingWorkers for removed listings proper payload" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed_remove.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(4)
        job = WriteListingWorker.jobs.first
        msg = LinkMessage.new(job["args"].first)
        expect(msg.url).to match(/avantlink\.com/)
        expect(msg.page_attributes).to be_nil
        expect(msg.page_is_valid?).to be_false
        expect(msg.page_not_found?).to be_true
      end

      it "should add a link to the ImageQueue for each new or updated listing" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed.xml") do |file|
              file.read
            end
          end
        end

        ProductFeedWorker.new.perform(domain: @site.domain)
        iq = ImageQueue.new(domain: @site.domain)
        expect(iq.size).to eq(4)
        expect(iq.pop).to match(/brownells\.com/)
      end
    end

    describe "internals" do
      before :each do
        @site = create_site "www.brownells.com"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear
        CDN.clear!
        Sidekiq::Worker.clear_all
      end

      it "should populate the db from a local file" do
        worker = ProductFeedWorker.new
        worker.perform(domain: @site.domain, filename: "spec/fixtures/avantlink_feeds/test_feed.xml")
        expect(WriteListingWorker.jobs.count).to eq(4)
      end

      it "does not blow up if the feed errors" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            "You have reached the maximum number of downloads for this feed in a 24-hour period."
          end
        end
        expect {
          ProductFeedWorker.new.perform(domain: @site.domain)
        }.not_to raise_error
      end

      it "does not blow up if the feed 404s" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            404
          end
        end
        expect {
          ProductFeedWorker.new.perform(domain: @site.domain)
        }.not_to raise_error
      end
    end
  end
end
