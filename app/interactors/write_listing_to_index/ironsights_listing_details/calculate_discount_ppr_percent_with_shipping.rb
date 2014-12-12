class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateDiscountPprPercentWithShipping
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless shipping_included? && discounted? && should_calculate_ppr?
        listing.discount.ppr_percent =
            calculate_discount_percent(list_price_per_round, with_shipping.price.per_round)
      end
    end
  end
end