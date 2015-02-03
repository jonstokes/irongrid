require 'spec_helper'

describe Site do

  # NOTE: Major changes:
  # 1. This now exists entirely in redis as "www.domain.com" => "JSON hash" , and is removed from postgres.
  # 2. There is no link_sources hash. There are only seed_links, some of which
  #    have a PAGENUM and some don't. The CreateLinksWorker can differentiate between the two.

  describe "#initialize" do
    it "should load its data from local repo when source: is :local" do
      pending "Example"
      expect(true).to eq(false)
    end

    it "should load its data from fixtures when source: is :fixture" do
      site = Site.new(domain: "www.retailer.com", source: :fixture)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Test Retailer")
      expect(site.read_interval).to eq(1440)
    end

    it "should load its data from redis when source: is :redis" do
      create_site "www.retailer.com"
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Test Retailer")
      expect(site.read_interval).to eq(1440)
    end

    it "should load its data from github when source: is :github" do
      pending "Example"
      expect(true).to eq(false)
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

    it "should not overwrite the stats that are already in redis" do
      create_site "www.retailer.com"
      time = Time.now
      stalest_time = Time.now - 1.month
      site = Site.new(domain: "www.retailer.com", source: :redis)
      site.update_stats(
        active_listings: 1,
        inactive_listings: 1,
        stale_listings: 1,
        stalest_listing: stalest_time
      )

      # ScrapePagesWorker starts up
      site2 = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site2.stats[:active_listings]).to eq(1)
      expect(site2.stats[:inactive_listings]).to eq(1)
      expect(site2.stats[:stale_listings]).to eq(1)

      # SiteStatsWorker starts up somewhere else
      site3 = Site.new(domain: "www.retailer.com", source: :redis)
      site3.update_stats(active_listings: 2)

      # ScrapePagesWorker cleans up
      site2.mark_read!
      expect(site2.stats[:active_listings]).to eq(2)
      expect(site2.stats[:inactive_listings]).to eq(1)
      expect(site2.stats[:stale_listings]).to eq(1)

      # SiteStatsWorker keeps going
      site3.update_stats(inactive_listings: 2)

      site4 = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site4.stats[:active_listings]).to eq(2)
      expect(site4.stats[:inactive_listings]).to eq(2)
      expect(site4.stats[:stale_listings]).to eq(1)
      expect(site4.stats[:stalest_listing]).to eq(stalest_time)
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
