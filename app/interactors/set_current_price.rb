class SetCurrentPrice < CoreModel
  include Interactor

  def perform
    context[:current_price_in_cents] = case type
                                       when "AuctionListing"
                                         auction_current_price_in_cents
                                       when "RetailListing"
                                         retail_current_price_in_cents
                                       when "ClassifiedListing"
                                         price_in_cents
                                       end
  end

  def retail_current_price_in_cents
    sale_price_in_cents || price_in_cents
  end

  def auction_current_price_in_cents
    auction_prices.compact.sort.last
  end

  def auction_prices
    [
      buy_now_price_in_cents,
      current_bid_in_cents,
      minimum_bid_in_cents,
      reserve_in_cents
    ]
  end
end
