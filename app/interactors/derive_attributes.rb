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
