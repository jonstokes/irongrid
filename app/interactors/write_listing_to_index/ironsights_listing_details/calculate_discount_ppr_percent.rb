class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateDiscountPprPercent
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless discounted? && should_calculate_ppr?
        listing.discount.ppr_percent =
            calculate_discount_percent(list_price_per_round, listing.price.per_round)
      end
    end
  end
end