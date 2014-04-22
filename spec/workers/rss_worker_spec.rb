require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!


describe RssWorker do

  before :each do
    @site = create_site_from_repo "www.armslist.com"
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "reads an RSS feed and extract the products into the LinkMessageQueue" do
      Mocktra(@site.domain) do
        get '/feed.rss' do
          File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist_rss.xml") do |file|
            file.read
          end
        end
      end
      RssWorker.new.perform(domain: "www.armslist.com")
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
      expect(LinkMessageQueue.new(domain: @site.domain).size).to eq(25)
      url = "http://www.armslist.com/posts/2858994"
      expect(LinkMessageQueue.find(url)).not_to be_nil
      expect(LinkMessageQueue.new(domain: @site.domain).has_key?(url)).to be_true
      expect(PruneLinksWorker.jobs.count).to eq(1)
    end
  end
end
