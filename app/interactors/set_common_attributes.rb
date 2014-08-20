class SetCommonAttributes < CoreModel
  include Interactor

  def perform
    context[:title]                    = title
    context[:keywords]                 = keywords
    context[:description]              = listing_json.description
    context[:category1]                = category1
    context[:upc]                      = listing_json.upc
    context[:mpn]                      = listing_json.mpn
    context[:sku]                      = listing_json.sku
    context[:seller_domain]            = listing_json.seller_domain
    context[:seller_name]              = listing_json.seller_name
    context[:affiliate_link_tag]       = site.affiliate_link_tag
    context[:affiliate_program]        = site.affiliate_program
    context[:image_source]             = image_source
    context[:item_condition]           = item_condition
    context[:item_location]            = item_location
    context[:auction_ends]             = auction_ends
  end

  def title
    ElasticSearchObject.new("title", raw: listing_json['title'])
  end

  def keywords
    ElasticSearchObject.new("keywords", raw: listing_json['keywords'])
  end

  def image_source
    return unless listing_json['image']
    return unless image_source = clean_up_image_url(listing_json['image'])
    unless is_valid_image_url?(image_source)
      notify "## IMAGE ERROR at #{url}. Image source is #{image_source}"
      return nil
    end
    image_source
  end

  def item_condition
    if ['New', 'Used'].include? listing_json['condition']
      listing_json['condition']
    else
      adapter.default_item_condition.try(:titleize) || "Unknown"
    end
  end

  def item_location
    return listing_json['location'] if listing_json['location'].present?
    adapter.default_item_location
  end

  def category1
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
