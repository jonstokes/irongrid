module Shipping
  class SetShippingAttributes
    include Interactor::Organizer

    def perform
      context[:current_price_in_cents_with_shipping] = calculate_current_price_in_cents_with_shipping
      context[:price_per_round_in_cents_with_shipping] = ppr_with_shipping
    end

    def calculate_current_price_in_cents_with_shipping
      return context[:current_price_in_cents] unless context[:shipping_cost_in_cents]
      context[:current_price_in_cents] + context[:shipping_cost_in_cents]
    end

    def ppr_with_shipping
      return unless context[:shipping_cost_in_cents] && context[:number_of_rounds]
      context[:price_per_round_in_cents] + (shipping_cost_in_cents.to_f / number_of_rounds.raw.to_f).round
    end
  end
end
