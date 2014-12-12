class WriteListingToIndex
  class IronsightsListingDetails
    include Interactor

    before do
      context.listing.shipping ||= {}
      context.listing.shipping.included = !!context.listing.shipping.try(:cost)
    end

    def call
      return unless context.listing.price.try(:current)

      if should_calculate_shipping?
        result = CalculateShipping.call(
            product:  context.product,
            price:    context.listing.price,
            shipping: context.listing.shipping
        )
        context.listing.with_shipping = result.with_shipping
      end

      if should_calculate_ppr?
        result = CalculatePricePerRound.call(
            number_of_rounds: context.product.number_of_rounds,
            price:            context.listing.price,
            list_ppr:         list_ppr
        )
        context.listing.price.per_round = result.price_per_round
        context.listing.discount.ppr_percent =result.discount_ppr_percent
      end

      if should_calculate_shipping? && should_calculate_ppr?
        result = CalculatePricePerRound.call(
            number_of_rounds:       context.product.number_of_rounds,
            price:                  context.listing.with_shipping.price,
            list_ppr:               list_ppr
        )
        context.listing.with_shipping.price.per_round = result.price_per_round
        context.listing.with_shipping.discount.ppr_percent = result.discount_ppr_percent
      end
    end

    def should_calculate_shipping?
      context.listing.shipping.included
    end

    def should_calculate_ppr?
      context.product.ammunition? && context.product.number_of_rounds && !context.product.number_of_rounds.zero?
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