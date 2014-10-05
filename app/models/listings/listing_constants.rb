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

  def es_objects
    self.class.index_objects
  end

  def item_data_attributes
    self.class.index_fields +
      GeoData::DATA_KEYS
  end

end
