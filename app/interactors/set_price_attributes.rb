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

    context[:current_price_in_cents_with_shipping] = calculate_current_price_in_cents_with_shipping
  end

  def calculate_current_price_in_cents_with_shipping
    return context[:current_price_in_cents] unless context[:shipping_cost_in_cents] && context[:current_price_in_cents]
    context[:current_price_in_cents] + context[:shipping_cost_in_cents]
  end

end
