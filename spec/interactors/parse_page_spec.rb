require 'spec_helper'
require 'digest/md5'
require 'mocktra'

describe ParsePage do

  before :all do
    create_parser_tests
  end

  describe "#perform" do
    before :each do
    end

    it "should correctly parse a standard, in-stock retail listing from Hyatt Gun Store" do
      include PageUtils
      site = create_site "www.hyattgunstore.com", source: :local
      page = load_listing_source("Retail", "www.hyattgunstore.com", "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can")
      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed.xml") do |file|
            page[:html]
          end
        end
      end

      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )

      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.category1.map(&:category1).compact.first).to eq("Ammunition")
      expect(item.caliber_category.map(&:caliber_category).compact.first).to eq("rifle")
      expect(item.title.map(&:title).compact.first.downcase).to eq("federal xm855 5.56 ammo 62 grain fmj, 420 rounds, stripper clips in ammo can")
      expect(item.item_condition).to eq("New")
      expect(item.image_source.downcase).to eq("http://www.hyattgunstore.com/images/p/76472-p.jpg")
      expect(item.keywords).to eq("Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,")
      expect(item.description.downcase).to include("federal 5.56 ammo in a can is available in")
      expect(item.price_in_cents).to be_nil
      expect(item.sale_price_in_cents).to eq(34999)
      expect(item.current_price_in_cents).to eq(34999)
    end

    it "can be re-used on two consecutive listings" do
      page = load_listing_source("Retail", "www.hyattgunstore.com", "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.hyattgunstore.com"))
      scraper.parse(url: page[:url], doc: doc)
      scraper.raw_listing['title'].downcase.should == "federal xm855 5.56 ammo 62 grain fmj, 420 rounds, stripper clips in ammo can"

      page = load_listing_source("Retail", "www.hyattgunstore.com", 'Ruger New Vaquero .45 Colt Stainless 5.5"')
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper.parse(url: page[:url], doc: doc)
      scraper.raw_listing['title'].downcase.should == 'ruger new vaquero .45 colt stainless 5.5"'
    end
  end

  describe "#listing" do
    it "should correctly clean up a standard, in stock retail listing from Hyatt Gun Store" do
      page = load_listing_source("Retail", "www.hyattgunstore.com", "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.hyattgunstore.com"))
      scraper.parse(doc: doc, url: page[:url])

      scraper.raw_listing.should_not be_nil
      scraper.listing['item_data']['category1'].first['category1'].should == "Ammunition"
      scraper.listing['item_data']['caliber_category'].first['caliber_category'].should == "rifle"
      scraper.listing['item_data']['title'].first['title'].downcase.should == "federal xm855 5.56 ammo 62 grain fmj, 420 rounds, stripper clips in ammo can"
      scraper.listing['item_data']['item_condition'].should == "New"
      scraper.listing['item_data']['image_source'].downcase.should == "http://www.hyattgunstore.com/images/p/76472-p.jpg"
      scraper.listing['item_data']['keywords'].should == "Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,"
      scraper.listing['item_data']['description'].downcase.should include("federal 5.56 ammo in a can is available in")
      scraper.listing['item_data']['price_in_cents'].should be_nil
      scraper.listing['item_data']['sale_price_in_cents'].should == 34999
      scraper.listing['item_data']['availability'].should == "in_stock"
      scraper.listing['item_data']['item_location'].should == "3332 Wilkinson Blvd Charlotte, NC 28208"
      scraper.not_found?.should be_false
    end

    it "should correctly clean up a standard, out of stock retail listing from Impact Guns" do
      page = load_listing_source("Retail", "www.impactguns.com", "Remington 22LR CYCLONE 36HP 5000 CAS")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.impactguns.com"))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing.should_not be_nil

      scraper.listing['item_data']['category1'].first['category1'].should == "Ammunition"
      scraper.listing['item_data']['caliber_category'].first['caliber_category'].should == "rimfire"
      scraper.listing['item_data']['title'].first['title'].should == "Remington 22LR CYCLONE 36HP 5000 CAS"
      scraper.listing['item_data']['item_condition'].should == "New"
      scraper.listing['item_data']['image_source'].should == "http://www.impactguns.com/data/default/images/catalog/535/REM_22CYCLONE_CASE.jpg"
      scraper.listing['item_data']['keywords'].should == "Remington, Remington 22LR CYCLONE 36HP 5000 CAS, 10047700482016"
      scraper.listing['item_data']['description'].should include("Remington-Remington")
      scraper.listing['item_data']['price_in_cents'].should be_nil
      scraper.listing['item_data']['sale_price_in_cents'].should be_nil
      scraper.listing['item_data']['availability'].should == "out_of_stock"
      scraper.listing['item_data']['item_location'].should == "2710 South 1900 West, Ogden, UT 84401"
      scraper.not_found?.should be_false
    end

    it "should correctly clean up a classified listing from Armslist" do
      page = load_listing_source("Classified", "www.armslist.com", "fast sale springfield xd 45")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.armslist.com"))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing.should_not be_nil
      scraper.listing['item_data']['title'].first['title'].should == "fast sale springfield xd 45"
      scraper.listing['item_data']['item_condition'].should == "Unknown"
      scraper.listing['item_data']['image_source'].downcase.should == "http://cdn2.armslist.com/sites/armslist/uploads/posts/2013/05/24/1667211_01_fast_sale_springfield_xd_45_640.jpg"
      scraper.listing['item_data']['keywords'].should be_nil
      scraper.listing['item_data']['description'].should include("For sale a springfield xd")
      scraper.listing['item_data']['price_in_cents'].should == 52500
      scraper.listing['item_data']['sale_price_in_cents'].should be_nil
      scraper.listing['item_data']['availability'].should == "in_stock"
      scraper.listing['item_data']['item_location'].should == "lacey/olympia, Southwest Washington, Washington"
      scraper.is_valid?.should be_true
   end

    it "should correctly clean up a CTD retail listing using meta tags" do
      page = load_listing_source("Retail", "www.cheaperthandirt.com", 'Ammo 16 Gauge Lightfield Commander IDS 2-3/4" Lead 7/8 Oz Slug 1630 fps 5 Round Box LFCP-16')
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.cheaperthandirt.com"))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing.should_not be_nil

      scraper.raw_listing['description'].should include("Lightfield offers many great hunting")
      scraper.listing['item_data']['description'].should include("Lightfield offers many great hunting")
      scraper.raw_listing['image'].should == "http://cdn1.cheaperthandirt.com/ctd_images/mdprod/3-0307867.jpg"
      scraper.listing['item_data']['image_source'].downcase.should == "http://cdn1.cheaperthandirt.com/ctd_images/mdprod/3-0307867.jpg"
      scraper.raw_listing['price'].should == "$12.21"
      scraper.listing['item_data']['price_in_cents'].should == 1221
    end

    it "should correctly clean up a BGS retail listing using meta_og tags" do
      page = load_listing_source("Retail", "www.budsgunshop.com", "Silva Olive Drab Compass")
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.budsgunshop.com"))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing.should_not be_nil

      scraper.raw_listing['title'].should == "Silva Olive Drab Compass"
      scraper.listing['item_data']['title'].first['title'].should == "Silva Olive Drab Compass"
      scraper.raw_listing['image'].should ==  "http://www.budsgunshop.com/catalog/images/15118.jpg"
      scraper.listing['item_data']['image_source'].downcase.should == "http://www.budsgunshop.com/catalog/images/15118.jpg"
    end

    it "should correctly clean up an auction listing from Gunbroker.com" do
      pending "I need a new parser test for an ended auction on GB"
      page = load_listing_source("Auction", "www.gunbroker.com", 'Aimpoint Micro H-1 4MOA LRP/Sp.39mm Rifle Scope')
      doc = Nokogiri.parse(page[:html], page[:url])
      scraper = ListingScraper.new(create_site("www.gunbroker.com"))
      scraper.parse(doc: doc, url: page[:url])
      scraper.raw_listing.should_not be_nil
      scraper.listing['item_data']['auction_ends'].should == Time.parse("2025-09-07 16:24:14 UTC")
    end
  end
end
