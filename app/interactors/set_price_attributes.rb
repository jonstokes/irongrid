class SetPriceAttributes
  include Interactor

  def perform
    case type
    when "RetailListing"
      set_retail_price_attributes
    when "ClassifiedListing"
      set_classified_price_attributes
    when "AuctionListing"
      set_auction_price_attributes
    end
  end

  def set_retail_price_attributes
    context[:price_in_cents]         = price_in_cents
    context[:sale_price_in_cents]    = sale_price_in_cents
    context[:price_on_request]       = price_on_request
  end

  def set_classified_price_attributes
    context[:price_in_cents]         = price_in_cents
  end

  def set_auction_price_attributes
    context[:buy_now_price_in_cents] = buy_now_price_in_cents
    context[:current_bid_in_cents]   = current_bid_in_cents
    context[:minimum_bid_in_cents]   = minimum_bid_in_cents
    context[:reserve_in_cents]       = reserve_in_cents
  end

  def buy_now_price_in_cents
    ListingFormat.price(raw_listing['buy_now_price'])
  end

  def current_bid_in_cents
    ListingFormat.price(raw_listing['current_bid'])
  end

  def minimum_bid_in_cents
    ListingFormat.price(raw_listing['minimum_bid'])
  end

  def reserve_in_cents
    ListingFormat.price(raw_listing['reserve'])
  end

  def price_in_cents
    ListingFormat.price(raw_listing['price'])
  end

  def sale_price_in_cents
    ListingFormat.price(raw_listing['sale_price'])
  end

  def price_on_request
    raw_listing['price_on_request']
  end
end
