class SetPriceAttributes
  include Interactor

  def perform
    %w(
      current_price_in_cents
      price_in_cents
      sale_price_in_cents
      price_on_request
      buy_now_price_in_cents
      current_bid_in_cents
      minimum_bid_in_cents
      reserve_in_cents
    ).map(&:to_sym).each do |key|
      context[key] = listing_json[key]
    end
  end

end
