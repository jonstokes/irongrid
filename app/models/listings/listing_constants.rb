module ListingConstants
  INDEXED_ATTRIBUTES = [
    :type,
    :url,
    :digest,
    :created_at,
    :updated_at,
    :seller_domain,
    :image,
    :upc,
    :mpn,
    :sku,
    :auction_ends
  ]

  ITEM_DATA_ATTRIBUTES =[
    'shipping_cost_in_cents',
    'discount_in_cents',
    'discount_percent',
    'discount_in_cents_with_shipping',
    'discount_percent_with_shipping',
    'weight_in_pounds',
    'seller_name',
    'description',
    'keywords',
    'image_source',
    'item_condition',
    'item_location',
    'availability',
    'current_price_in_cents',
    'current_price_in_cents_with_shipping',
    'price_per_round_in_cents',
    'price_per_round_in_cents_with_shipping',
    'price_on_request',
    'price_in_cents',
    'sale_price_in_cents',
    'buy_now_price_in_cents',
    'current_bid_in_cents',
    'minimum_bid_in_cents',
    'reserve_in_cents',
    'affiliate_link_tag',
    'affiliate_program',
    GeoData::DATA_KEYS
  ].flatten

end
