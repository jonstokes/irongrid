require 'spec_helper'

describe Site do

  # NOTE: Major changes:
  # 1. This now exists entirely in redis as "www.domain.com" => "JSON hash" , and is removed from postgres.
  # 2. There is no link_sources hash. There are only seed_links, some of which
  #    have a PAGENUM and some don't. The CreateLinksWorker can differentiate between the two.

  describe "#initialize" do
    it "should load its data from local repo when source: is :local" do
      site = Site.new(domain: "www.retailer.com", source: :local)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Test Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.read_interval).to eq(1440)
      expect(site.page_adapter.keys).to include("title")
    end

    it "should load its data from fixtures when source: is :fixture" do
      site = Site.new(domain: "www.retailer.com", source: :fixture)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.read_interval).to eq(86400)
      expect(site.page_adapter.keys).to include("title")
    end

    it "should load its data from redis when source: is :redis" do
      create_site "www.retailer.com"
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.read_interval).to eq(86400)
      expect(site.page_adapter.keys).to include("title")
    end

    it "should load its data from github when source: is :github" do
      pending "Example"
    end
  end

  describe "#refresh_only?" do
    it "is false when a site is not refresh_only" do
      site = create_site "www.retailer.com"
      expect(site.refresh_only?).to be_false
    end

    it "is true when a site is refresh_only" do
      site = Site.new(domain: "www.impactguns.com", source: :local)
      expect(site.refresh_only?).to be_true
    end
  end

  describe "#feeds" do
    it "returns an array of properly formatted Feed objects for the site's feeds" do
      site = Site.new(domain: "www.brownells.com", source: :local)
      expect(site.feeds.count).to eq(1)
      feed = site.feeds.first
      expect(feed).to be_a(Feed)
      expect(feed.format).to eq(:xml)
      expect(feed.url).to eq('http://datafeed.avantlink.com/download_feed.php?id=153279&auth=ad2088b086dfc98f918a37e8fa32fcf3&incr=all-status')
      expect(feed.feed_url).to eq("http://datafeed.avantlink.com/download_feed.php?id=153279&auth=ad2088b086dfc98f918a37e8fa32fcf3&incr=all-status&from=#{(Time.now - 1.day).strftime("%Y-%m-%d")}")
      expect(feed.product_xpath).to eq('//Products/Product')
      expect(feed.product_link_xpath).to eq('//Buy_Link')
    end

    it "expands links with PAGENUM in the into the correct number of individual feeds" do
      site = Site.new(domain: "www.blucoreshootingcenter.com", source: :local)
      feeds = site.feeds
      expect(feeds.count).to eq(237)
    end

    it "should properly expand each PAGENUM link" do
      site = Site.new(domain: "www.blucoreshootingcenter.com", source: :local)
      feed = site.feeds.detect { |f| f.feed_url == 'http://www.blucoreshootingcenter.com/c-11-firearms.aspx?pagesize=48&pagenum=100' }
      expect(feed).to be_a(Feed)
      expect(feed.product_link_prefix).to eq('http://www.blucoreshootingcenter.com/')
      expect(feed.product_link_xpath).to eq("//td[@class='entityPageProdNameCell']/a/@href")
      expect(feed.format).to eq(:html)
    end

    it "is empty if there are no feeds" do
      site = Site.new(domain: "www.impactguns.com", source: :local)
      expect(site.feeds).to be_empty
    end
  end

  describe "#udpate" do
    it "should update a string of attributes in redis" do
      site = create_site "www.retailer.com"
      time = Time.now
      site.update(read_interval: 0, read_at: time)
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.read_interval).to eq(0)
      expect(site.read_at).to eq(time)
    end
  end

  describe "::domains" do
    it "returns an array of all the current Site domains in redis" do
      create_site "www.retailer.com"
      site = create_site "www.budsgunshop.com"
      domains = Site.domains
      expect(domains).to include("www.retailer.com")
      expect(domains).to include("www.budsgunshop.com")
    end
  end
end
