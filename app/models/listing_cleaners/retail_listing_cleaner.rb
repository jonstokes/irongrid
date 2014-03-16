class RetailListingCleaner < ListingCleaner

  def type
    "RetailListing"
  end

  def is_valid?
    !!(eval validation_string)
  end

  def current_price_in_cents
    sale_price_in_cents || price_in_cents
  end

  def stock_status
    #FIXME: Convert all this stock_status stuff to availability at some point.
    # This will ruin all the digests, though.
    if ["In Stock", "Out Of Stock"].include? raw_listing['stock_status']
      return raw_listing['stock_status']
    elsif raw_listing['in_stock_message']
      return "In Stock"
    elsif raw_listing['out_of_stock_message']
      return "Out Of Stock"
    else
      site.default_stock_status.try(:titleize) || "N/A"
    end
  end

  def price_in_cents
    convert_price(raw_listing['price'])
  end

  def price_on_request
    raw_listing['price_on_request']
  end

  def sale_price_in_cents
    convert_price(@raw_listing['sale_price'])
  end

  def default_digest_attributes
    %w(title image description keywords type seller_domain item_condition item_location current_price_in_cents stock_status)
  end
end
