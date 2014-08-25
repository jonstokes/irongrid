class SetCommonAttributes < CoreModel
  include Interactor

  def perform
    context[:url]                = listing_json.url
    context[:type]               = listing_json['type']
    context[:title]              = title
    context[:keywords]           = keywords
    context[:description]        = listing_json.description
    context[:availability]       = listing_json.availability
    context[:category1]          = product_category1
    context[:upc]                = listing_json.product_upc
    context[:mpn]                = listing_json.product_mpn
    context[:sku]                = listing_json.product_sku
    context[:seller_domain]      = site.domain
    context[:seller_name]        = site.name
    context[:affiliate_link_tag] = site.affiliate_link_tag
    context[:affiliate_program]  = site.affiliate_program
    context[:image_source]       = listing_json.image
    context[:item_condition]     = listing_json.condition
    context[:item_location]      = listing_json.location
    context[:auction_ends]       = auction_ends
  end

  def title
    ElasticSearchObject.new("title", raw: listing_json.title)
  end

  def keywords
    ElasticSearchObject.new("keywords", raw: listing_json.keywords)
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
