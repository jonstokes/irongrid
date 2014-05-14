require 'spec_helper'

describe GenerateListingHash do
  it "generates a hash that can be used to create a listing" do
    site = create_site "www.hyattgunstore.com", source: :local
    opts = {
      adapter: site.page_adapter,
      digest: "a0b57db0491562882035e833183d44bb",
      url: "http://www.hyattgunstore.com/federal-xm855-5.56-ammo-62-grain-fmj-420-rounds-on-30-round-stripper-clips.html",
      type: "RetailListing",
      title: ElasticSearchObject.new(
        "title",
        raw: "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        autocomplete: "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        scrubbed: "Federal XM855 5.56 Ammo 62 Grain FMJ 420 Rounds Stripper Clips in Ammo Can",
        normalized: "Federal xm855 5.56 NATO ammo 62 grain fmj 420 rounds stripper clips in ammo can"
      ),
      keywords: ElasticSearchObject.new(
        "keywords",
        raw: "Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,",
        scrubbed: "Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,",
        normalized: "Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,"
      ),
      category1: ElasticSearchObject.new(
        "category1",
        raw: "Ammunition",
        classification_type: "hard"
      ),
      caliber_category: ElasticSearchObject.new(
        "caliber_category",
        raw: "rifle",
        classification_type: "metadata"
      ),
      manufacturer: ElasticSearchObject.new(
        "manufacturer",
        raw: "Federal",
        classification_type: "metadata"
      ),
      caliber: ElasticSearchObject.new(
        "caliber",
        raw: "5.56 NATO",
        classification_type: "metadata"
      ),
      number_of_rounds: ElasticSearchObject.new(
        "number_of_rounds",
        raw: 420,
        classification_type: "metadata"
      ),
      grains: ElasticSearchObject.new(
        "grains",
        raw: 62,
        classification_type: "metadata"
      ),
      seller_name: "Hyatt Gun Store",
      seller_domain: "www.hyattgunstore.com",
      description: "Federal 5.56 Ammo in a can is available in 420 round or 840 round ammo cans. The cans are packed with 30 round boxes of (3) 10 shot strip clips. This ammo is 62 grain full metal jacket. Shipped in a 30 caliber military ammo can.",
      image_source: "http://www.hyattgunstore.com/images/P/76472-P.jpg",
      image_download_attempted: false,
      affiliate_link_tag: nil,
      item_condition: "New",
      item_location: "3332 Wilkinson Blvd Charlotte, NC 28208",
      stock_status: "In Stock",
      current_price_in_cents: 34999,
      price_per_round_in_cents: 83,
      price_on_request: nil,
      price_in_cents: nil,
      sale_price_in_cents: 34999,
      buy_now_price_in_cents: nil,
      current_bid_in_cents: nil,
      minimum_bid_in_cents: nil,
      reserve_in_cents: nil,
      auction_ends: nil,
      city: nil,
      state: nil,
      country: nil,
      latitude: nil,
      longitude: nil,
      state_code: nil,
      postal_code: nil,
      country_code: nil,
      coordinates: nil
    }

    result = GenerateListingHash.perform(opts)
    listing = Listing.create(result.listing)
    Listing.index.refresh
    item = Listing.index.retrieve "retail_listing", listing.id
    %w(url digest).each do |attr|
      expect(item.send(attr)).to eq(opts[attr.to_sym])
    end
    Listing::ITEM_DATA_ATTRIBUTES.each do |attr|
      if attr == "keywords"
        expect(item.keywords).to eq(opts[:keywords].raw)
      else
        expect(item.send(attr)).to eq(opts[attr.to_sym])
      end
    end
    Listing::ES_OBJECTS.each do |attr|
      expect(item.send(attr).map { |k| k.send(attr) }.compact.first).to eq(opts[attr.to_sym].raw)
      expect(item.send(attr).map(&:classification_type).compact.first).to eq(opts[attr.to_sym].classification_type)
    end
  end
end
