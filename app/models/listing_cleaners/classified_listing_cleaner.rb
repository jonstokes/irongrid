class ClassifiedListingCleaner < ListingCleaner

  def type
    "ClassifiedListing"
  end

  def is_valid?
    !!(eval validation_string) && !classified_sold?
  end

  def current_price_in_cents
    sale_price_in_cents || price_in_cents
  end

  def stock_status
    "In Stock"
  end

  def price_in_cents
    convert_price(raw_listing['price'])
  end

  def sale_price_in_cents
    convert_price(@raw_listing['sale_price'])
  end

  def classified_sold?
    return !!@raw_listing['item_sold']
  end

  def default_digest_attributes
    DEFAULT_DIGEST_ATTRIBUTES + %w(sale_price_in_cents price_in_cents)
  end
end
