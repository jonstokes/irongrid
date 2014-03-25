class AuctionListingCleaner < ListingCleaner

  def type
    "AuctionListing"
  end

  def is_valid?
    !!(eval validation_string) && !auction_ended?
  end

  def stock_status
    "In Stock"
  end

  def buy_now_price_in_cents
    convert_price(@raw_listing['buy_now_price'])
  end

  def current_bid_in_cents
    convert_price(@raw_listing['current_bid'])
  end

  def minimum_bid_in_cents
    convert_price(@raw_listing['minimum_bid'])
  end

  def reserve_in_cents
    convert_price(@raw_listing['reserve'])
  end

  def auction_ends
    convert_time(@raw_listing['auction_ends'])
  end

  def auction_ended?
    return false unless type == "AuctionListing"
    return raw_listing['auction_ends'].nil? || (convert_time(raw_listing['auction_ends']) < Time.now)
  end

  def default_digest_attributes
    %w(title image_source description keywords type seller_domain item_condition item_location stock_status auction_ends)
  end

  def current_price_in_cents
    auction_prices.compact.sort.last
  end

  private

  def auction_prices
    [
      buy_now_price_in_cents,
      current_bid_in_cents,
      minimum_bid_in_cents,
      reserve_in_cents
    ]
  end

end
