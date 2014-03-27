require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!


describe RssWorker do

  before :each do
    @site = create_site_from_repo "www.armslist.com"
    Mocktra(@site.domain) do
      get '/feed.rss' do
        File.open("#{Rails.root}/spec/fixtures/rss_feeds/armslist_rss.xml") do |file|
          file.read
        end
      end
    end
    LinkQueue.new(domain: @site.domain).clear
    LinkData.delete_all
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    it "should read an RSS feed and extract the products into LinkData" do
      RssWorker.new.perform(domain: "www.armslist.com")
      expect(LinkData.size).to eq(26)
      url = "http://www.armslist.com/posts/2858994"
      expect(LinkData.find(url)).not_to be_nil
      expect(LinkQueue.new(domain: @site.domain).has_key?(url)).to be_true
      expect(ScrapePagesWorker.jobs.count).to eq(1)
      expect(LogRecordWorker.jobs.count).to eq(2)
    end
  end
end
