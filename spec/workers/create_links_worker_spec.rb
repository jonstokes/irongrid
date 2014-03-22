require 'spec_helper'
require 'mocktra'

describe CreateLinksWorker do

  before :all do
    @site = create_site_from_repo "www.retailer.com"
    Mocktra(@site.domain) do
      get '/products' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/products.html") do |file|
          file.read
        end
      end
    end
  end

  before :each do
    @worker = CreateLinksWorker.new
  end

  after :each do
    LinkSet.new(domain: @site.domain).clear
  end

  describe "#perform" do

    it "transitions to ScrapePagesWorker if there are links in the LinkSet" do
      links = (0..445).map { |i| { "http://www.retailer.com/products/#{i}" => {id: i, digest: "abcdefg#{i}"} }
      LinkSet.new(domain: @site.domain).add links
      CreateLinksWorker.new.perform(domain: @site.domain)
      expect(ScrapePagesWorker.jobs.count).to eq(1)
    end

    it "does not transition to ScrapePagesWorker if LinkSet is empty" do
      pending "Mock product page with zero links?"
      expect(LinkSet.new(domain: @site.domain).size).to eq(0)
      expect(ScrapePagesWorker.jobs.count).to eq(0)
    end
  end

  describe "#seed_links" do
    it "should load any seed links as a hash" do
      create_site_from_repo("www.budsgunshop.com")
      @worker.init(domain: "www.budsgunshop.com")
      @worker.seed_links.should be_a Hash
      @worker.seed_links.has_key?("http://www.budsgunshop.com/catalog/index.php/manufacturers_id/1000/sort/6a/page/1").should be_true
    end

    it "should be empty if there are no seed links" do
      create_site_from_repo("www.hyattgunstore.com")
      @worker.init(domain: "www.hyattgunstore.com")
      @worker.seed_links.should be_empty
    end
  end

  describe "#compressed_links" do
    before :each do
      create_site_from_repo("www.gunbroker.com")
    end

    it "should expand compressed links as a hash" do
      @worker.init(domain: "www.gunbroker.com")
      @worker.compressed_links.should be_a Hash
    end

    it "should expand the right number of links" do
      @worker.init(domain: "www.gunbroker.com")
      @worker.compressed_links.size.should == 130
    end

    it "should properly expand each link" do
      @worker.init(domain: "www.gunbroker.com")
      @worker.compressed_links.has_key?("http://www.gunbroker.com/Collectible-Firearms/BI.aspx?Sort=7&PageSize=75&PageIndex=2").should be_true
    end

    it "should be empty if there are no compressed links" do
      create_site_from_repo("www.cheaperthandirt.com")
      @worker.init(domain: "www.cheaperthandirt.com")
      @worker.compressed_links.should be_empty
    end
  end

  describe "#link_list" do
    it "should yield an array of all links of the right length" do
      create_site_from_repo("www.gunbroker.com")
      @worker.init(domain: "www.gunbroker.com")
      @worker.link_list.should be_a Array
      @worker.link_list.size.should == 130
    end
  end

  describe "#links_with_attrs" do
    it "should return a combined hash of seed links and compressed links with all attributes" do
      create_site_from_repo("www.gunbroker.com")
      @worker.init(domain: "www.gunbroker.com")
      @worker.links_with_attrs["http://www.gunbroker.com/Charity-Gun-Auctions/BI.aspx?Sort=7&PageSize=75&PageIndex=10"].should_not be_nil
      @worker.links_with_attrs["http://www.gunbroker.com/Charity-Gun-Auctions/BI.aspx?Sort=7&PageSize=75&PageIndex=10"]["link_xpaths"].first.should == '//a[@class="BItmTLnk"]/@href'
    end
  end
end
