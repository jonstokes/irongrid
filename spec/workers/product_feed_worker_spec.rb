require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe ProductFeedWorker do
  describe "#perform" do
    describe "write to listings table from a generic full product feed" do
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

      it "removes a link from the LMQ before updating if the RefreshLinksWorker had added it" do
        Mocktra(@site.domain) do
          get '/media/feeds/genericammofeed.xml' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed.xml") do |file|
              file.read
            end
          end
        end
        url = "http://ammo.net/prvi-partizan-380-acp-ammo-50-rounds-94-grain-fmj-380-acp-ammunition-from-prvi-partizan"
        LinkMessageQueue.add(LinkMessage.new(url: url))
        ProductFeedWorker.new.perform(domain: @site.domain)
        expect(WriteListingWorker.jobs.count).to eq(18)
        expect(LogRecordWorker.jobs.count).to eq(2)
        expect(LinkMessageQueue.has_key?(url)).to be_false
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

    describe "write to listings table from Avanlink feed" do
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

    describe "populate LMQ from web pages" do
      before :each do
        @site = create_site "www.retailer.com"
        Mocktra(@site.domain) do
          get '/products' do
            File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/products.html") do |file|
              file.read
            end
          end
        end
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear
      end

      it "does not add links to the LinkMessageQueue if they're already there" do
        pending "Example"
      end

      it "exits early if the site is being read by another worker" do
        pending "Example"
      end

      it "reads a product page and extracts the links into the LinkMessageQueue" do
        @worker.perform(domain: @site.domain)
        expect(LinkMessageQueue.new(domain: @site.domain).size).to eq(444)
      end
    end

    describe "populate LMQ from RSS and XML link feeds" do
      before :each do
        @site = create_site "www.armslist.com"
        LinkMessageQueue.new(domain: @site.domain).clear
        ImageQueue.new(domain: @site.domain).clear
      end

      it "reads an RSS feed and extracts the products into the LinkMessageQueue" do
        Mocktra(@site.domain) do
          get '/feed.rss' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist_rss.xml") do |file|
              file.read
            end
          end
        end

        @worker.perform(domain: "www.armslist.com")
        expect(LinkMessageQueue.new(domain: @site.domain).size).to eq(25)
        url = "http://www.armslist.com/posts/2841625"
        expect(LinkMessageQueue.find(url)).not_to be_nil
        expect(LinkMessageQueue.new(domain: @site.domain).has_key?(url)).to be_true
        expect(LogRecordWorker.jobs.count).to eq(2)
      end

      it "does not blow up when the RSS feed 404s" do
        Mocktra(@site.domain) do
          get '/feed.rss' do
            404
          end
        end
        expect {
          @worker.perform(domain: "www.armslist.com")
        }.not_to raise_error
      end

      it "does not blow up when the feed contains UTF-8 chars that Nokogiri can't translate to ASCII" do
        Mocktra(@site.domain) do
          get '/feed.rss' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist2_rss.xml") do |file|
              file.read
            end
          end
        end
        expect {
          @worker.perform(domain: "www.armslist.com")
        }.not_to raise_error
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

      it "does not blow up when the feed contains UTF-8 chars that Nokogiri can't translate to ASCII" do
        site = create_site "www.armslist.com"
        Mocktra(site.domain) do
          get '/feed.rss' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist2_rss.xml") do |file|
              file.read
            end
          end
        end
        expect {
          @worker.perform(domain: site.domain)
        }.not_to raise_error
      end
    end
  end
end
