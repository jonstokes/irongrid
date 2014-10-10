require 'spec_helper'
require 'digest/md5'
require 'mocktra'

describe ParseJson do

  before :all do
    create_parser_tests
    @page = Hashie::Mash.new(
      fetched: true,
      body: "string",
      code: 200
    )
  end

  describe "#perform" do
    before :each do
      Stretched::Registration.clear_all
      register_globals
      load_scripts
    end

    it "fails on an invalid listing" do
      site = create_site "www.hyattgunstore.com"

      listing = File.open("spec/fixtures/stretched/output/hyatt-invalid.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to be_false
      expect(result.status).to eq(:invalid)
      expect(result.is_valid?).to be_false
    end

    it "should correctly parse a standard, in-stock retail listing from Hyatt Gun Store" do
      site = create_site "www.hyattgunstore.com"

      listing = File.open("spec/fixtures/stretched/output/hyatt-standard-instock.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to be_true
      expect(result.is_valid?).to be_true
      expect(result.not_found?).to be_false
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.category1.map(&:category1).compact.first).to eq("Ammunition")
      expect(item.seller_domain).to eq(site.domain)
      expect(item.caliber_category.map(&:caliber_category).compact.first).to eq("rifle")
      expect(item.manufacturer.map(&:manufacturer).compact.first).to eq("Federal")
      expect(item.title.map(&:title).compact.first.downcase).to eq("federal xm855 5.56 ammo 62 grain fmj, 420 rounds, stripper clips in ammo can")
      expect(item.item_condition.downcase).to eq("new")
      expect(item.image_source.downcase).to eq("http://www.hyattgunstore.com/images/p/76472-p.jpg")
      expect(item.keywords).to eq("Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,")
      expect(item.description.downcase).to include("federal 5.56 ammo in a can is available in")
      expect(item.price_in_cents).to be_nil
      expect(item.sale_price_in_cents).to eq(34999)
      expect(item.current_price_in_cents).to eq(34999)
    end

    it "parses a standard, out of stock retail listing from Impact Guns" do
      site = create_site "www.impactguns.com", source: :fixture

      listing = File.open("spec/fixtures/stretched/output/impact-standard-outofstock.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site:site
      )

      expect(result.success?).to be_true
      expect(result.is_valid?).to be_true
      expect(result.not_found?).to be_false
      listing = Listing.create(result.listing)

      expect(listing.item_condition).to eq("new")
      expect(listing.image_source).to eq("http://www.impactguns.com/data/default/images/catalog/535/REM_22CYCLONE_CASE.jpg")
      expect(listing.keywords).to eq("Remington, Remington 22LR CYCLONE 36HP 5000 CAS, 10047700482016")
      expect(listing.description).to include("Remington-Remington")
      expect(listing.price_in_cents).to be_nil
      expect(listing.sale_price_in_cents).to be_nil
      expect(listing.current_price_in_cents).to be_nil
      expect(listing.availability).to eq("out_of_stock")
      expect(listing.item_location).to eq("2710 South 1900 West, Ogden, UT 84401")
    end

    it "parses a classified listing from Armslist" do
      site = create_site "www.armslist.com"

      listing = File.open("spec/fixtures/stretched/output/armslist.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to be_true
      expect(result.is_valid?).to be_true
      expect(result.not_found?).to be_false
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
      expect(item.item_location).to include("Southwest Washington")
    end

    it "parses a CTD retail listing using meta tags" do
      site = create_site "www.cheaperthandirt.com"

      listing = File.open("spec/fixtures/stretched/output/ctd-meta-tags.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to be_true
      expect(result.is_valid?).to be_true
      expect(result.not_found?).to be_false
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.description).to include("Lightfield offers many great hunting")
      expect(item.image_source).to eq("http://cdn1.cheaperthandirt.com/ctd_images/mdprod/3-0307867.jpg")
      expect(item.price_in_cents).to eq(1221)
    end

    it "parses a BGS retail listing using meta_og tags" do
      site = create_site "www.budsgunshop.com"

      listing = File.open("spec/fixtures/stretched/output/bgs-metaog-tags.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = ParseJson.perform(
        page: @page,
        object: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to be_true
      expect(result.is_valid?).to be_true
      expect(result.not_found?).to be_false
      listing = Listing.create(result.listing)
      Listing.index.refresh
      item = Listing.index.retrieve "retail_listing", listing.id

      expect(item.title.map(&:title).compact.first).to eq("Silva Olive Drab Compass")
      expect(item.image_source).to eq("http://www.budsgunshop.com/catalog/images/15118.jpg")
    end
  end
end
