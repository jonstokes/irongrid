module Ironsights
  module ListingCalculations
    def product
      context.product
    end

    def listing
      context.listing
    end

    def discounted?
      listing.discount.try(:in_cents) && !listing.discount.in_cents.zero?
    end

    def with_shipping
      context.listing.with_shipping ||= {}
    end

    def shipping_cost
      context.listing.shipping.try(:cost)
    end

    def weight
      product.weight.try(:shipping)
    end

    def shipping_included?
      context.listing.shipping.included ||= !!shipping_cost
    end

    def number_of_rounds
      product.number_of_rounds
    end

    def list_price_per_round
      if list_price
        (list_price.to_f / number_of_rounds.to_f).round.to_i
      end
    end

    def list_price
      listing.price.list || product.msrp
    end

    def calculate_price_per_round(price)
      (price.to_f / number_of_rounds.to_f).round.to_i
    end

    def calculate_discount_in_cents(list_price, sale_price)
      return 0 unless list_price > sale_price
      list_price - sale_price
    end

    def calculate_discount_percent(list_price, sale_price)
      return 0 unless (list_price > sale_price) && !sale_price.zero?
      (list_price.to_f / sale_price.to_f).round * 100
    end

    def should_calculate_ppr?
      product.ammunition? && number_of_rounds && !number_of_rounds.zero?
    end
  end
end