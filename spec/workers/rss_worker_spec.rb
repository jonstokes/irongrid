require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!


describe RssWorker do

  before :each do
    @site = create_site_from_repo "www.armslist.com"
    LinkQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "reads an RSS feed and extract the products into LinkData" do
      Mocktra(@site.domain) do
        get '/feed.rss' do
          File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist_rss.xml") do |file|
            file.read
          end
        end
      end
      RssWorker.new.perform(domain: "www.armslist.com")
      expect(LinkData.size).to eq(26)
      url = "http://www.armslist.com/posts/2858994"
      expect(LinkData.find(url)).not_to be_nil
      expect(LinkQueue.new(domain: @site.domain).has_key?(url)).to be_true
      expect(LogRecordWorker.jobs.count).to eq(2)
    end

    it "does not blow up when the RSS feed 404s" do
      Mocktra(@site.domain) do
        get '/feed.rss' do
          404
        end
      end
      expect {
        RssWorker.new.perform(domain: "www.armslist.com")
      }.not_to raise_error
    end

  end

  describe "#transition" do
    it "transitions to PruneLinksWorker if it has added any links" do
      Mocktra(@site.domain) do
        get '/feed.rss' do
          File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist_rss.xml") do |file|
            file.read
          end
        end
      end
      RssWorker.new.perform(domain: "www.armslist.com")
      expect(LinkData.size).to eq(26)
      url = "http://www.armslist.com/posts/2858994"
      expect(LinkData.find(url)).not_to be_nil
      expect(LinkQueue.new(domain: @site.domain).has_key?(url)).to be_true
      expect(PruneLinksWorker.jobs.count).to eq(1)
    end
  end
end
