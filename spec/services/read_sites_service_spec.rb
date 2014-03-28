require 'spec_helper'

describe ReadSitesService do
  it "should use DMS" do
    pending "Example"
  end

  describe "RefreshLinksWorker" do
    before :each do
      @site = create_site_from_repo "www.retailer.com"
      @site.read_with = "RefreshLinksWorker"
      @site.send(:write_to_redis)
      @service = ReadSitesService.new
      @lq = LinkQueue.new(domain: @site.domain)

      @lq.clear
    end

    it "should read a RefreshLinksWorker site if its LinkQueue is empty and it should be read" do
      @site.read_at = 10.days.ago
      @site.send(:write_to_redis)
      5.times { FactoryGirl.create(:retail_listing, updated_at: Time.now - 10.days) }
      @service.start
      @service.stop
      expect(@lq.size).to eq(5)
    end

    it "should not read a RefreshLinksWorker site if its LinkQueue is not empty" do
      5.times { |i| @lq.push "http://#{@site.domain}/#{i + 10}" }
      @site.read_at = 10.days.ago
      @site.send(:write_to_redis)
      5.times { FactoryGirl.create(:retail_listing, updated_at: Time.now - 10.days) }
      @service.start
      @service.stop
      expect(@lq.size).to eq(5)
      expect(@lq.has_key?(Listing.first.url)).to be_false
    end
  end

  describe "CreateLinksWorker" do
    before :each do
      @site = create_from_repo "www.retailer.com"
      @site.read_with = "CreateLinksWorker"
      @site.send(:write_to_redis)
      @service = ReadSitesService.new
    end

    it "should read a CreateLinksWorker site if its LinkQueue is empty and it should be read" do
    end

    it "should not read a CreateLinksWorker site if its LinkQueue is not empty" do
      pending "Example"
    end
  end

  it "should not read a CLW or RLW site if it should not be read" do
    pending "Example"
  end

  it "should read an AvantlinkWorker site with the correct worker" do
    pending "Example"
  end

  it "should read an RssWorker site with the correct worker" do
    pending "Example"
  end

  it "should read a CreateLinksWorker site with the correct worker" do
    pending "Example"
  end

  it "should read a RefreshLinksWorker site with the correct worker" do
    pending "Example"
  end
end
