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

  ES_OBJECTS = %w(
    title
    category1
    caliber_category
    manufacturer
    caliber
    number_of_rounds
    grains
  )

  ITEM_DATA_ATTRIBUTES =[
    'shipping_cost_in_cents',
    'discount_in_cents',
    'discount_percent',
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


  ES_OBJECTS.each do |key|
    define_method key do
      item_data[key]
    end

    define_method "#{key}=" do |value|
      item_data_will_change! unless item_data[key] == [{key => value}]
      item_data[key] = [{key => value}]
    end
  end

  ITEM_DATA_ATTRIBUTES.each do |key|
    define_method key do
      item_data[key]
    end
    define_method "#{key}=" do |value|
      item_data_will_change! unless item_data[key] == value
      item_data[key] = value
    end
  end
end
