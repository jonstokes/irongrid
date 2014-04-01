module ListingConstants
  ES_OBJECTS = %w(
    title
    category1
    caliber_category
    manufacturer
    caliber
    number_of_rounds
    grains
  )

  INDEXED_ATTRIBUTES = [
    :type,
    :url,
    :created_at,
    :updated_at,
    :coordinates,
    GeoData::DATA_KEYS
  ].flatten

  COMMON_ATTRIBUTES = %w(
    seller_name
    seller_domain
    description
    keywords
    image
    image_source
    item_condition
    image_download_attempted
    item_location
    availability
    current_price_in_cents
    price_per_round_in_cents
  )
  RETAIL_ATTRIBUTES = %w(
    price_on_request
    price_in_cents
    sale_price_in_cents
  )
  CLASSIFIED_ATTRIBUTES = %w(
    price_in_cents
    sale_price_in_cents
  )
  AUCTION_ATTRIBUTES = %w(
    buy_now_price_in_cents
    current_bid_in_cents
    minimum_bid_in_cents
    reserve_in_cents
    auction_ends
  )

  TYPE_SPECIFIC_ATTRIBUTES = (RETAIL_ATTRIBUTES + CLASSIFIED_ATTRIBUTES + AUCTION_ATTRIBUTES).uniq
  ITEM_DATA_ATTRIBUTES = COMMON_ATTRIBUTES + TYPE_SPECIFIC_ATTRIBUTES

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
