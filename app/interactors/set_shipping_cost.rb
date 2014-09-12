module Shipping
  class SetShippingCost
    include Interactor

    def perform
      context[:shipping_cost_in_cents] = listing_json.shipping_cost_in_cents || calculate_shipping_cost
    end

    def calculate_shipping_cost
      site.shipping_calculator.set_context(instance: listing_json, context: context)
    end
  end
end
