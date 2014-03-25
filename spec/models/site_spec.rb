require 'spec_helper'

describe Site do

  # NOTE: Major changes:
  # 1. This now exists entirely in redis as "www.domain.com" => "JSON hash" , and is removed from postgres.
  # 2. There is no service_options hash. There are only seed_links, some of which
  #    have a PAGENUM and some don't. The CreateLinksWorker can differentiate between the two.

  describe "#initialize" do
    before :each do
      @site = Site.new(domain: "www.retailer.com", source: :local)
      @site.send(:write_to_redis)
    end

    it "should load its data from local repo when source: is :local" do
      expect(@site.domain).to eq("www.retailer.com")
      expect(@site.name).to eq("Test Retailer")
      expect(@site.scrape_with_service).to eq("CreateLinksService")
      expect(@site.active).to eq(true)
      expect(@site.read_interval).to eq(86400)
      expect(@site.adapter.keys).to include("title")
    end

    it "should load its data from redis when source: is :redis" do
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Test Retailer")
      expect(site.scrape_with_service).to eq("CreateLinksService")
      expect(site.active).to eq(true)
      expect(site.read_interval).to eq(86400)
      expect(site.adapter.keys).to include("title")
    end

    it "should load its data from github when source: is :github" do
      pending "Example"
    end
  end

  describe "#udpate" do
    before :each do
      @site = Site.new(domain: "www.retailer.com", source: :local)
      @site.send(:write_to_redis)
    end

    it "should update a string of attributes in redis" do
      time = Time.now
      @site.update(read_interval: 0, read_at: time)
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.read_interval).to eq(0)
      expect(site.read_at).to eq(time)
    end
  end
end
