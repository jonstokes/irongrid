require 'spec_helper'

describe CreateLinksWorker do
  before :each do
    @worker = CreateLinksWorker.new
  end

  describe "#perform" do
    it "will not start if another worker is reading this domain" do
      pending "Example"
    end

    it "spawns a RefreshLinksWorker instance when it starts" do
      pending "Example"
      #It spawns an RefreshLinksWorker.perform(domain: domain) to start populating
      #the LinkSet for this domain in parallel with the crawl. This way, existing listings
      #will have database ids for them and be updated.
    end

    it "adds links to a site's LinkSet from a seed url" do
      pending "Example"
      # LinkSet << { url: link }
    end

    it "adds links to a site's LinkSet from a compressed url" do
      pending "Example"
      # LinkSet << { url: link }
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
