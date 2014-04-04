require 'spec_helper'

describe Site do

  # NOTE: Major changes:
  # 1. This now exists entirely in redis as "www.domain.com" => "JSON hash" , and is removed from postgres.
  # 2. There is no service_options hash. There are only seed_links, some of which
  #    have a PAGENUM and some don't. The CreateLinksWorker can differentiate between the two.

  describe "#initialize" do
    it "should load its data from local repo when source: is :local" do
      site = Site.new(domain: "www.retailer.com", source: :local)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Test Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.active).to eq(true)
      expect(site.read_interval).to eq(86400)
      expect(site.adapter.keys).to include("title")
    end

    it "should load its data from fixtures when source: is :fixture" do
      site = Site.new(domain: "www.retailer.com", source: :fixture)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.active).to eq(true)
      expect(site.read_interval).to eq(86400)
      expect(site.adapter.keys).to include("title")
    end

    it "should load its data from redis when source: is :redis" do
      create_site_from_repo "www.retailer.com"
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.domain).to eq("www.retailer.com")
      expect(site.name).to eq("Retailer")
      expect(site.read_with).to eq("RefreshLinksWorker")
      expect(site.active).to eq(true)
      expect(site.read_interval).to eq(86400)
      expect(site.adapter.keys).to include("title")
    end

    it "should load its data from github when source: is :github" do
      pending "Example"
    end
  end

  describe "#refresh_only?" do
    it "is false when a site is not refresh_only" do
      site = create_site_from_repo "www.retailer.com"
      expect(site.refresh_only?).to be_false
    end

    it "is true when a site is refresh_only" do
      site = Site.new(domain: "www.impactguns.com", source: :local)
      expect(site.refresh_only?).to be_true
    end
  end

  describe "#udpate" do
    it "should update a string of attributes in redis" do
      site = create_site_from_repo "www.retailer.com"
      time = Time.now
      site.update(read_interval: 0, read_at: time)
      site = Site.new(domain: "www.retailer.com", source: :redis)
      expect(site.read_interval).to eq(0)
      expect(site.read_at).to eq(time)
    end
  end

  describe "::active" do
    it "returns an array of all sites currently active in redis" do
      create_site_from_repo "www.retailer.com"
      site = create_site_from_repo "www.budsgunshop.com"
      site.update(active: false)
      expect(Site.active.count).to eq(1)
      expect(Site.active.first).to be_a(Site)
    end
  end
end
