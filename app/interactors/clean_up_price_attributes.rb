class CleanUpPriceAttributes
  include Interactor

  def perform
    case type
    when "RetailListing"
      context[:item_data]['price_in_cents']         = price_in_cents
      context[:item_data]['sale_price_in_cents']    = sale_price_in_cents
    when "ClassifiedListing"
      context[:item_data]['price_in_cents']         = price_in_cents
    when "AuctionListing"
      context[:item_data]['buy_now_price_in_cents'] = buy_now_price_in_cents
      context[:item_data]['current_bid_in_cents']   = current_bid_in_cents
      context[:item_data]['minimum_bid_in_cents']   = minimum_bid_in_cents
      context[:item_data]['reserve_in_cents']       = reserve_in_cents
    end
  end

  def buy_now_price_in_cents
    ListingFormat.price(@raw_listing['buy_now_price'])
  end

  def current_bid_in_cents
    ListingFormat.price(@raw_listing['current_bid'])
  end

  def minimum_bid_in_cents
    ListingFormat.price(@raw_listing['minimum_bid'])
  end

  def reserve_in_cents
    ListingFormat.price(@raw_listing['reserve'])
  end

  def price_in_cents
    ListingFormat.price(raw_listing['price'])
  end

  def sale_price_in_cents
    ListingFormat.price(@raw_listing['sale_price'])
  end
end
