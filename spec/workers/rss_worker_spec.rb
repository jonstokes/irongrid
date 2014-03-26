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
  end

  describe "#perform" do
    it "should read an RSS feed and extract the products into LinkData" do
      RssWorker.new.perform(domain: "www.armslist.com")
      expect(LinkData.size).to eq(30)
      url = "http://www.armslist.com/posts/2858994"
      expect(LinkData.find(url)).not_to be_nil
      expect(LinkQueue.new(domain: @site.domain).has_key?(url)).to be_true
    end
  end
end
