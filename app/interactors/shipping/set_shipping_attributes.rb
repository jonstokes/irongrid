module Shipping
  class SetShippingAttributes
    include Interactor::Organizer

    def perform
      return unless context[:current_price_in_cents]
      context[:current_price_in_cents_with_shipping] = calculate_current_price_in_cents_with_shipping
      context[:price_per_round_in_cents_with_shipping] = ppr_with_shipping
      context[:discount_in_cents_with_shipping] = discount_price_with_shipping
      context[:discount_percent_with_shipping] = discount_percent_shipping
    end

    def calculate_current_price_in_cents_with_shipping
      return context[:current_price_in_cents] unless context[:shipping_cost_in_cents]
      context[:current_price_in_cents] + context[:shipping_cost_in_cents]
    end

    def ppr_with_shipping
      return unless context[:shipping_cost_in_cents] && context[:number_of_rounds]
      context[:price_per_round_in_cents] + (shipping_cost_in_cents.to_f / number_of_rounds.raw.to_f).round
    end

    def discount_price_with_shipping
      return unless context[:shipping_cost_in_cents] && context[:discount_in_cents]
      discount = discount_in_cents - shipping_cost_in_cents
      discount > 0 ? discount : 0
    end

    def discount_percent_shipping
      return unless context[:discount_in_cents_with_shipping]
      dp = (discount_in_cents_with_shipping.to_f / current_price_in_cents.to_f) * 100
      dp.to_i
    end
  end
end
