class WriteListingToIndex
  class IronsightsListingDetails
    include Interactor

    before do
      context.listing.shipping ||= {}
      context.listing.shipping.included = !!context.listing.shipping.try(:cost)
    end

    def call
      return unless context.listing.price.try(:current)
      calculate_shipping if should_calculate_shipping?
      calculate_price_per_round if should_calculate_ppr?
      calculate_ppr_with_shipping if should_calculate_shipping? && should_calculate_ppr?
    end

    def calculate_shipping
      result = CalculateShipping.call(
          product:       context.product,
          discount:      context.listing.discount.try(:in_cents),
          price:         context.listing.price,
          shipping_cost: context.listing.shipping.cost
      )
      context.listing.with_shipping = result.with_shipping
    end

    def calculate_price_per_round
      result = CalculatePricePerRound.call(
          number_of_rounds: context.product.number_of_rounds,
          discount:         context.listing.discount.try(:in_cents),
          price:            context.listing.price.current,
          list_ppr:         list_ppr
      )
      context.listing.price.per_round = result.price_per_round
      context.listing.discount.ppr_percent =result.discount_ppr_percent
    end

    def calculate_ppr_with_shipping
      result = CalculatePricePerRound.call(
          number_of_rounds:       context.product.number_of_rounds,
          discount:               context.listing.with_shipping.discount.try(:in_cents),
          price:                  context.listing.with_shipping.price.current,
          list_ppr:               list_ppr
      )
      context.listing.with_shipping.price.per_round = result.price_per_round
      context.listing.with_shipping.discount.ppr_percent = result.discount_ppr_percent
    end

    def should_calculate_shipping?
      context.listing.shipping.included
    end

    def should_calculate_ppr?
      context.product.ammunition? && context.product.number_of_rounds && !context.product.number_of_rounds.zero?
    end

    def price_per_round(price, number_of_rounds)
      (price.to_f / number_of_rounds.to_f).round.to_i
    end

    def discount_ppr_percent(ppr)
      calculate_discount_percent(list_ppr, ppr)
    end

    def list_ppr
      @list_ppr ||= begin
        if context.listing.price.list
          (context.listing.price.list.to_f / context.listing.product.number_of_rounds.to_f).round.to_i
        end
      end
    end

  end
end