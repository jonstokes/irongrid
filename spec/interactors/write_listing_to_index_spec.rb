require 'spec_helper'
require 'digest/md5'
require 'mocktra'

describe WriteListingToIndex do

  describe '#call' do
    before :each do
      initialize_stretched
      @page = Hashie::Mash.new(
          fetched: true,
          body: "string",
          code: 200
      )
    end

    it 'fails on an invalid listing' do
      site = create_site "www.hyattgunstore.com"

      listing = File.open("spec/fixtures/stretched/output/hyatt-invalid.json", "r") do |f|
        JSON.parse(f.read)
      end.first

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(false)
      expect(result.error).to eq('invalid')
    end

    it 'correctly parses a standard, in-stock retail listing from Hyatt Gun Store' do
      site = create_site "www.hyattgunstore.com"

      listing = File.open("spec/fixtures/stretched/output/hyatt-standard-instock.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      item = IronBase::Listing.find(result.listing.id).hits.first

      expect(item.product.category1).to eq("ammunition")
      expect(item.seller.domain).to eq(site.domain)
      expect(item.product.caliber_category).to eq("rifle")
      expect(item.product.manufacturer).to eq("Federal")
      expect(item.title.downcase).to eq("federal xm855 5.56 ammo 62 grain fmj, 420 rounds, stripper clips in ammo can")
      expect(item.condition.downcase).to eq("new")
      expect(item.image.source.downcase).to eq("http://www.hyattgunstore.com/images/p/76472-p.jpg")
      expect(item.keywords).to eq("Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,")
      expect(item.description.downcase).to include("federal 5.56 ammo in a can is available in")
      expect(item.price.list).to be_nil
      expect(item.price.sale).to eq(34999)
      expect(item.price.current).to eq(34999)
    end

    it 'updates a listing with new values' do
      site = create_site "www.hyattgunstore.com"

      listing = File.open("spec/fixtures/stretched/output/hyatt-standard-instock.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      pending "Finish it"
    end

    it 'parses a standard, out of stock retail listing from Impact Guns' do
      site = create_site "www.impactguns.com"

      listing_json = File.open("spec/fixtures/stretched/output/impact-standard-outofstock.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing_json),
        site:site
      )

      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      listing = IronBase::Listing.find(result.listing.id).hits.first

      expect(listing.condition).to eq("new")
      expect(listing.image.source).to eq("http://www.impactguns.com/data/default/images/catalog/535/REM_22CYCLONE_CASE.jpg")
      expect(listing.keywords).to eq("Remington, Remington 22LR CYCLONE 36HP 5000 CAS, 10047700482016")
      expect(listing.description).to include("Remington-Remington")
      expect(listing.price).to be_nil
      expect(listing.availability).to eq("out_of_stock")
      expect(listing.location.id).to eq("2710 South 1900 West, Ogden, UT 84401".upcase)
    end

    it 'parses a classified listing from Armslist' do
      site = create_site "www.armslist.com"

      listing = File.open("spec/fixtures/stretched/output/armslist.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      item = IronBase::Listing.find(result.listing.id).hits.first

      expect(item.product.category1).to eq("guns")
      expect(item.title.downcase).to eq("fast sale springfield xd 45")
      expect(item.condition).to eq("unknown")
      expect(item.image.source).to eq("http://cdn2.armslist.com/sites/armslist/uploads/posts/2013/05/24/1667211_01_fast_sale_springfield_xd_45_640.jpg")
      expect(item.keywords).to be_nil
      expect(item.description).to include("For sale a springfield xd")
      expect(item.price.list).to eq(52500)
      expect(item.price.sale).to be_nil
      expect(item.price.current).to eq(52500)
      expect(item.availability).to eq("in_stock")
      expect(item.location.id).to include("Southwest Washington".upcase)
    end

    it "parses a CTD retail listing using meta tags" do
      site = create_site "www.cheaperthandirt.com"

      listing = File.open("spec/fixtures/stretched/output/ctd-meta-tags.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      item = IronBase::Listing.find(result.listing.id).hits.first

      expect(item.description).to include("Lightfield offers many great hunting")
      expect(item.image.source).to eq("http://cdn1.cheaperthandirt.com/ctd_images/mdprod/3-0307867.jpg")
      expect(item.price.list).to eq(1221)
    end

    it "parses a BGS retail listing using meta_og tags" do
      site = create_site "www.budsgunshop.com"

      listing = File.open("spec/fixtures/stretched/output/bgs-metaog-tags.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
        page: @page,
        listing_json: Hashie::Mash.new(listing),
        site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      item = IronBase::Listing.find(result.listing.id).hits.first

      expect(item.title).to eq("Silva Olive Drab Compass")
      expect(item.image.source).to eq("http://www.budsgunshop.com/catalog/images/15118.jpg")
    end

    it 'adds a product to the index, and links that product to the listing' do
      site = create_site "www.budsgunshop.com"

      listing = File.open("spec/fixtures/stretched/output/bgs-metaog-tags.json", "r") do |f|
        JSON.parse(f.read)
      end.first.merge(engine: 'ironsights')

      result = WriteListingToIndex.call(
          page: @page,
          listing_json: Hashie::Mash.new(listing),
          site: site
      )
      expect(result.success?).to eq(true)
      IronBase::Listing.refresh_index

      expect(IronBase::Product.count).to eq(1)
      product = IronBase::Product.first
      expect(product.upc).not_to be_nil

      item = IronBase::Listing.find(result.listing.id).hits.first
      expect(item.product_source.id).not_to be_nil
    end

  end
end
