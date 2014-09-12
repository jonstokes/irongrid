module Shipping
  class SetShippingCost
    include Interactor

    def perform
      context[:shipping_cost_in_cents] = listing_json.shipping_cost_in_cents || calculate_shipping_cost
    end

    def calculate_shipping_cost
      return unless runner = Script.runner("#{site.domain}/shipping") rescue nil
      instance = Hashie::Mash.new(context)
      runner.run(instance).shipping_cost_in_cents
    end
  end
end