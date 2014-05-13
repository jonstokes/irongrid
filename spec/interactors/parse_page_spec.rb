require 'spec_helper'
require 'digest/md5'
require 'mocktra'

describe ParsePage do

  before :all do
    create_parser_tests
  end

  describe "#perform" do

    it "returns the proper error message for a not found listing" do
      pending "Example"
    end

    it "returns the proper error message for an invalid listing" do
      pending "Example"
    end

    it "returns the proper error message for a sold classified" do
      pending "Example"
    end

    it "returns the proper error message for an ended auction" do
      pending "Example"
    end

    it "should correctly parse a standard, in-stock retail listing from Hyatt Gun Store" do
      site = create_site "www.hyattgunstore.com", source: :local
      page = load_listing_source("Retail", "www.hyattgunstore.com", "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can")
      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          page[:html]
        end
      end

      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )
      expect(result.success?).to be_true
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

    it "parses a standard, out of stock retail listing from Impact Guns" do
      site = create_site "www.impactguns.com", source: :local
      page = load_listing_source("Retail", "www.impactguns.com", "Remington 22LR CYCLONE 36HP 5000 CAS")

      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          page[:html]
        end
      end
      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )
      expect(result.success?).to be_true
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.category1.map(&:category1).compact.first).to eq("Ammunition")
      expect(item.caliber_category.map(&:caliber_category).compact.first).to eq("rimfire")
      expect(item.title.map(&:title).compact.first).to eq("Remington 22LR CYCLONE 36HP 5000 CAS")
      expect(item.item_condition).to eq("New")
      expect(item.image_source).to eq("http://www.impactguns.com/data/default/images/catalog/535/REM_22CYCLONE_CASE.jpg")
      expect(item.keywords).to eq("Remington, Remington 22LR CYCLONE 36HP 5000 CAS, 10047700482016")
      expect(item.description).to include("Remington-Remington")
      expect(item.price_in_cents).to be_nil
      expect(item.sale_price_in_cents).to be_nil
      expect(item.current_price_in_cents).to be_nil
      expect(item.availability).to eq("out_of_stock")
      expect(item.item_location).to eq("2710 South 1900 West, Ogden, UT 84401")
    end

    it "parses a classified listing from Armslist" do
      site = create_site "www.armslist.com", source: :local
      page = load_listing_source("Classified", "www.armslist.com", "fast sale springfield xd 45")

      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          page[:html]
        end
      end
      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )
      expect(result.success?).to be_true
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "classified_listing", listing.id

      expect(item.category1.map(&:category1).compact.first).to eq("Guns")
      expect(item.title.map(&:title).compact.first).to eq("fast sale springfield xd 45")
      expect(item.item_condition).to eq("Unknown")
      expect(item.image_source).to eq("http://cdn2.armslist.com/sites/armslist/uploads/posts/2013/05/24/1667211_01_fast_sale_springfield_xd_45_640.jpg")
      expect(item.keywords).to be_nil
      expect(item.description).to include("For sale a springfield xd")
      expect(item.price_in_cents).to eq(52500)
      expect(item.sale_price_in_cents).to be_nil
      expect(item.current_price_in_cents).to eq(52500)
      expect(item.availability).to eq("in_stock")
      expect(item.item_location).to eq("lacey/olympia, Southwest Washington, Washington")
   end

    it "parses a CTD retail listing using meta tags" do
      site = create_site "www.cheaperthandirt.com", source: :local
      page = load_listing_source("Retail", "www.cheaperthandirt.com", 'Ammo 16 Gauge Lightfield Commander IDS 2-3/4" Lead 7/8 Oz Slug 1630 fps 5 Round Box LFCP-16')

      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          page[:html]
        end
      end
      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )
      expect(result.success?).to be_true
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.description).to include("Lightfield offers many great hunting")
      expect(item.image_source).to eq("http://cdn1.cheaperthandirt.com/ctd_images/mdprod/3-0307867.jpg")
      expect(item.price_in_cents).to eq(1221)
    end

    it "parses a BGS retail listing using meta_og tags" do
      site = create_site "www.budsgunshop.com", source: :local
      page = load_listing_source("Retail", "www.budsgunshop.com", "Silva Olive Drab Compass")

      url = "http://#{site.domain}/1.html"
      Mocktra(site.domain) do
        get '/1.html' do
          page[:html]
        end
      end
      page = PageUtils::Test.fetch_page(url)
      result = ParsePage.perform(
        site: site,
        page: page,
        adapter_type: :page
      )
      expect(result.success?).to be_true
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.title.map(&:title).compact.first).to eq("Silva Olive Drab Compass")
      expect(item.image_source).to eq("http://www.budsgunshop.com/catalog/images/15118.jpg")
    end
  end
end