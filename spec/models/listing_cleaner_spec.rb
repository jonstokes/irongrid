require 'spec_helper'
require 'digest/md5'

describe ListingCleaner do
  before :all do
    @site = create_site "www.hyattgunstore.com"
    @site.page_adapter['validation']['retail'] = "true"
    create_parser_tests
  end

  describe "#affiliate_link_tag" do
    it "adds an affiliate_link_tag field to item_data if the site has one" do
      site = Site.new(domain: "www.luckygunner.com", source: :fixture)
      site.send(:write_to_redis)

      url = "http://www.luckygunner.com/product1"
      raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => url,
        "category1" => "Ammunition"
      }
      clean_listing = RetailListingCleaner.new(raw_listing: raw_listing, url: url, site: site)
      expect(clean_listing.item_data['affiliate_link_tag']).to eq("#rid=ironsights&amp;chan=search")
    end

    it "does not add an affiliate_link_tag for a site that doesn't have one" do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => @url,
        "category1" => "Ammunition"
      }
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      expect(clean_listing.item_data['affiliate_link_tag']).to be_nil
    end
  end

  describe "#seller_domain and #seller_name" do
    it "pulls the seller info" do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => @url,
        "category1" => "Ammunition"
      }
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.item_data["seller_name"].should == @site.name
      clean_listing.item_data["seller_domain"].should == @site.domain
    end
  end

  describe "type-specific attributes" do
    it "is nil when not present" do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => @url,
        "category1" => "Ammunition"
      }
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.item_data.should have_key("auction_ends")
      clean_listing.auction_ends.should be_nil
      clean_listing.item_data.should have_key("buy_now_price_in_cents")
      clean_listing.buy_now_price_in_cents.should be_nil
      clean_listing.item_data.should have_key("coordinates")
      clean_listing.coordinates.should be_nil
    end
  end

  describe "#title" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => @url,
        "category1" => "Ammunition"
      }
    end

    it "correctly retrieves the title" do
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.title.should == @raw_listing['title']
    end

    it "correctly parses the title" do
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.to_h['item_data']['title'].should == [
        {"title" => @raw_listing['title']},
        {"autocomplete" => @raw_listing['title']},
        {"scrubbed" => "Federal XM855 5.56 Ammo 62 Grain FMJ 420 rounds"},
        {"normalized" => "Federal xm855 5.56 NATO ammo 62 grain fmj 420 rounds" },
      ]
    end
  end

  describe "#image_source" do
    it "should return a prefixed image url when appropriate" do
      page = load_listing_source("Retail", "www.impactguns.com", 'Remington 22LR CYCLONE 36HP 5000 CAS')
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(Site.new(domain: "www.impactguns.com", source: :local))
      scraper.parse(doc: doc, url: page[:url])
      scraper.listing["item_data"]["image_source"].should == "http://www.impactguns.com/data/default/images/catalog/535/REM_22CYCLONE_CASE.jpg"
    end

    it "should return the page image when no prefix is needed" do
      page = load_listing_source("Retail", "www.budsgunshop.com", "Silva Olive Drab Compass")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(Site.new(domain: "www.budsgunshop.com", source: :local))
      scraper.parse(doc: doc, url: page[:url])
      scraper.listing["item_data"]["image_source"].should == "http://www.budsgunshop.com/catalog/images/15118.jpg"
    end

    it "should return nil when the image is invalid" do
      page = load_listing_source("Retail", "www.budsgunshop.com", "Silva Olive Drab Compass")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(Site.new(domain: "www.budsgunshop.com", source: :local))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing['image'] = "http://www.budsgunshop.com/catalog/images/"
      scraper.listing["item_data"]["image_source"].should be_nil
    end
  end

  describe "#digest" do
    it "should correctly digest a standard, in-stock retail listing from Hyatt Gun Store" do
      page = load_listing_source("Retail", "www.hyattgunstore.com", "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(Site.new(domain: "www.hyattgunstore.com", source: :local))
      scraper.parse(doc: doc, url: page[:url])
      puts "#{scraper.listing}"
      scraper.listing["digest"].should == "600ff2d8e95a7ca170faad192123128e"
    end

    it "should add the URL to the digest on a site where that's required" do
      page = load_listing_source("Classified", "www.armslist.com", "fast sale springfield xd 45")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(Site.new(domain: "www.armslist.com", source: :local))
      scraper.parse(doc: doc, url: page[:url])
      puts "#{scraper.listing}"
      scraper.listing["digest"].should == "63d4ba4eb149d90ad1e28ff60dda0be8"
    end
  end

  describe "#category1" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
        "category1" => "Ammunition"
      }
    end

    it "correctly parses options and categorizes a listing" do
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.to_h['item_data']['category1'].should == [{"category1" => "Ammunition"}, {"classification_type" => "hard"}]
    end
  end

  describe "revisit_category" do
    it "categorizes and uncategorized listing based on extracted metadata" do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
      }
      clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
      clean_listing.to_h['item_data']['category1'].should == [{"category1" => "Ammunition"}, {"classification_type" => "metadata"}]
    end
  end

  describe "extended_item_data" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
        "category1" => "Ammunition"
      }
    end

    describe "#price_per_round_in_cents" do
      it "correctly calculates the price per round in cents" do
        @raw_listing.merge!(
          "title" => "Federal XM855 .44 FMJ",
          "number_of_rounds" => "250rnd",
          "price" => "$99.00"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['price_per_round_in_cents'].should == 40
      end
    end

    describe "#manufacturer" do
      it "correctly extracts the manufacturer from the raw_listing if it's explicit there" do
        @raw_listing.merge!(
          "title" => "Ammo, 420 Rounds",
          "manufacturer" => "Mfgr: Federal"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"hard"}]
      end

      it "correctly extracts the manufacturer from the title" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the manufacturer from the keywords" do
        @raw_listing.merge!(
          "title" => "Ammo, 420 Rounds",
          "keywords" => "Federal"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
      end
    end

    describe "it can tell the difference between manufacturer and caliber" do
      it "can tell the difference between Federal as mfgr and Remington as caliber" do
        @raw_listing.merge!("title" => "Federal .223 Remington Ammo, 400rnds")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>".223 Rem"}, {"classification_type"=>"metadata"}]
      end

      it "does not misidentify Remington as a manufacturer" do
        @raw_listing.merge!(
          "title" => ".223 Remington Ammo, 400rnds",
          "keywords" => "Federal"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>".223 Rem"}, {"classification_type"=>"metadata"}]
      end

      it "does not misidentify AAC as a manufacturer" do
        @raw_listing.merge!(
          "title" => ".300 aac blackout ammo, 400rnds",
          "keywords" => "Federal"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>".300 BLK"}, {"classification_type"=>"metadata"}]
      end
    end

    describe "#caliber_category" do

      it "correctly hard classifieds the caliber_category" do
        @raw_listing.merge!(
          "title" => "Federal Ammo, 420 Rounds",
          "caliber_category" => "rifle"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber_category'].should == [{"caliber_category" => "rifle"}, {"classification_type" => "hard"}]
      end

      it "correctly soft classifies the caliber_category as rifle" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber_category'].should == [{"caliber_category" => "rifle"}, {"classification_type" => "metadata"}]
      end

      it "correctly soft classifies the caliber_category as shotgun" do
        @raw_listing.merge!(
          "title" => "Federal Ammo, 420 Rounds",
          "caliber" => "Caliber: 20ga"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber_category'].should == [{"caliber_category" => "shotgun"}, {"classification_type" => "hard"}]
      end
    end


    describe "#caliber" do
      it "correctly extracts the caliber when it's explicitly present in raw_listing" do
        @raw_listing.merge!(
          "title" => "Federal Ammo, 420 Rounds",
          "caliber" => "Caliber: 20ga"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>"20 gauge"}, {"classification_type"=>"hard"}]
      end

      it "correctly extracts the caliber from the title" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>"5.56 NATO"}, {"classification_type"=>"metadata"}]

        @raw_listing.merge!("title" => "Federal XM855 5.56 Nato Ammo FMJ, 420 Rounds")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>"5.56 NATO"}, {"classification_type"=>"metadata"}]

        @raw_listing.merge!("title" => "Federal XM855 20ga Ammo FMJ, 420 Rounds")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>"20 gauge"}, {"classification_type"=>"metadata"}]

        @raw_listing.merge!("title" => "Federal XM855 .45acp 62 Grain FMJ, 420 Rounds")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>".45 ACP"}, {"classification_type"=>"metadata"}]
      end

      it "extracts .22lr from the title" do
        @raw_listing.merge!("title" => "Federal XM855 .22 LR 62 Grain FMJ, 420 Rounds")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>".22lr"}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the caliber from the keywords" do
        @raw_listing.merge!(
          "title" => "Federal XM855 62 Grain FMJ, 420 Rounds",
          "keywords" => "Federal, 20ga"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['caliber'].should == [{"caliber"=>"20 gauge"}, {"classification_type"=>"metadata"}]
      end
    end

    describe "#number_of_rounds" do
      it "correctly extracts the number of rounds from the raw_listing when it's present there" do
        @raw_listing.merge!(
          "title" => "Federal XM855 .44 FMJ",
          "number_of_rounds" => "420"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['number_of_rounds'].should == [{"number_of_rounds"=>420}, {"classification_type"=>"hard"}]
      end

      it "correctly extracts the number of rounds from the title" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['number_of_rounds'].should == [{"number_of_rounds"=>420}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the number of rounds from a 'box of rounds' type listing" do
        @raw_listing.merge!("title" => "Federal XM855 .22 LR 62 Grain FMJ, box of 4,000")
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['number_of_rounds'].should == [{"number_of_rounds"=>4000}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the number of rounds from the keywords" do
        @raw_listing.merge!(
          "title" => "Federal XM855 .44 FMJ",
          "keywords" => "420rnd"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['number_of_rounds'].should == [{"number_of_rounds"=>420}, {"classification_type"=>"metadata"}]
      end
    end

    describe "#grains" do
      it "correctly extracts the grains from the raw_listing if it's present there" do
        @raw_listing.merge!(
          "title" => "Federal XM855 .44 FMJ",
          "grains" => "62"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['grains'].should == [{"grains"=>62}, {"classification_type"=>"hard"}]
      end

      it "correctly extracts the grains from the title" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['grains'].should == [{"grains"=>62}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the grains from the keywords" do
        @raw_listing.merge!(
          "title" => "Federal XM855 .44 FMJ",
          "keywords" => "62gr"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['grains'].should == [{"grains"=>62}, {"classification_type"=>"metadata"}]
      end
    end
  end

  describe "#convert_price", no_es: true do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420rnds",
        "url" => @url,
        "category1" => "Ammunition"
      }
      @cleaner = RetailListingCleaner.new(site: @site, url: @url, raw_listing: @raw_listing)
    end

    it "should convert $1,000.99 to 100099" do
      @cleaner.convert_price("$1,000.00").should == 100000
    end

    it "should convvert $ 100 to 10000" do
      @cleaner.convert_price("$ 100").should == 10000
    end

    it "should convvert $ 1,000 to 100000" do
      @cleaner.convert_price("$ 1,000").should == 100000
    end

    it "should convvert $100. to 10000" do
      @cleaner.convert_price("$100.").should == 10000
    end

    it "should convvert $1,900. to 190000" do
      @cleaner.convert_price("$1,900.").should == 190000
    end

    it "should convvert $100.9 to 10090" do
      @cleaner.convert_price("$100.9").should == 10090
    end

    it "should covert $900.00. to 90000" do
      @cleaner.convert_price("$900.00.").should == 90000
    end
  end

end
