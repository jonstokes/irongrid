class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePricePerRoundWithShipping
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless shipping_included? && should_calculate_ppr?

        with_shipping.price.per_round =
            calculate_price_per_round(with_shipping.price.current)
      end
    end
  end
end