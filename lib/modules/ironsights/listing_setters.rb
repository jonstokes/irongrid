module Ironsights
  module ListingSetters
    def shipping_cost(value)
      context.listing.shipping.cost = value
    end

    def discount(value)
      context.listing.discount = value
    end

    def discount_with_shipping(value)
      context.listing.with_shipping.discount = value
    end

    def price_per_round(value)
      context.listing.price.per_round = value
    end

    def price_per_round_with_shipping(value)
      context.listing.with_shipping.price.per_round = value
    end

    def price_with_shipping(value)
      context.listing.with_shipping = value
    end
  end
end