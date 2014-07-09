module ListingConstants
  INDEXED_ATTRIBUTES = [
    :type,
    :url,
    :digest,
    :created_at,
    :updated_at,
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
    'seller_name',
    'seller_domain',
    'description',
    'keywords',
    'image',
    'image_source',
    'image_download_attempted',
    'item_condition',
    'item_location',
    'availability',
    'current_price_in_cents',
    'price_per_round_in_cents',
    'price_on_request',
    'price_in_cents',
    'sale_price_in_cents',
    'buy_now_price_in_cents',
    'current_bid_in_cents',
    'minimum_bid_in_cents',
    'reserve_in_cents',
    'auction_ends',
    'upc',
    'model_number',
    'sku',
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
