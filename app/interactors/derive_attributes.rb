class DeriveAttributes < CoreModel
  include Interactor

  def perform
    context[:title]              = title
    context[:keywords]           = keywords
    context[:category1]          = product_category1
    context[:seller_domain]      = site.domain
    context[:seller_name]        = site.name
    context[:affiliate_link_tag] = site.affiliate_link_tag
    context[:affiliate_program]  = site.affiliate_program
    context[:auction_ends]       = auction_ends
    context[:caliber]            = product_caliber
    context[:caliber_category]   = product_caliber_category
    context[:manufacturer]       = product_manufacturer
    context[:number_of_rounds]   = product_number_of_rounds
    context[:grains]             = product_grains
  end

  def title
    scrubbed = ProductDetails::Scrubber.scrub(listing_json.title, :inches, :punctuation, :color)
    ElasticSearchObject.new(
      "title",
      raw: listing_json.title,
      scrubbed: scrubbed,
      normalized: scrubbed,
      autocomplete: scrubbed
    )
  end

  def product_caliber
    return unless listing_json.product_caliber
    ElasticSearchObject.new(
      "caliber",
      raw: listing_json.product_caliber,
      classification_type: "hard"
    )
  end

  def product_caliber_category
    return unless listing_json.product_caliber_category
    ElasticSearchObject.new(
      "caliber_category",
      raw: listing_json.product_caliber_category,
      classification_type: "hard"
    )
  end

  def product_manufacturer
    return unless listing_json.product_manufacturer
    ElasticSearchObject.new(
      "manufacturer",
      raw: listing_json.product_manufacturer,
      classification_type: "hard"
    )
  end

  def product_grains
    return unless listing_json.product_manufacturer
    ElasticSearchObject.new(
      "grains",
      raw: listing_json.product_manufacturer,
      classification_type: "hard"
    )
  end

  def product_number_of_rounds
    return unless listing_json.product_number_of_rounds
    ElasticSearchObject.new(
      "number_of_rounds",
      raw: listing_json.product_number_of_rounds,
      classification_type: "hard"
    )
  end

  def product_category1
    hard_categorize("category1") ||
      ElasticSearchObject.new(
        "category1",
        raw:                  "None",
        classification_type: "fall_through"
      )
  end

  def hard_categorize(cat)
    return unless value = listing_json["product_#{cat}"]
    ElasticSearchObject.new(
      cat,
      raw: value,
      classification_type: "hard"
    )
  end

  def auction_ends
    return unless type == "AuctionListing"
    ListingFormat.time(site: site, time: listing_json['auction_ends'])
  end
end
