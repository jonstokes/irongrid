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
      listing.with_shipping ||= {}
    end

    def shipping_cost
      listing.shipping.try(:cost)
    end

    def weight
      product.weight.try(:shipping)
    end

    def shipping_included?
      listing.shipping ||= {}
      listing.shipping.included ||= !!shipping_cost
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

    def calculate_discount_in_cents(list, sale)
      return 0 unless list > sale
      list - sale
    end

    def calculate_discount_percent(list, sale)
      return 0 unless (list > sale) && !sale.zero?
      (list.to_f / sale.to_f).round * 100
    end

    def should_calculate_ppr?
      product.ammunition? && number_of_rounds && !number_of_rounds.zero?
    end
  end
end