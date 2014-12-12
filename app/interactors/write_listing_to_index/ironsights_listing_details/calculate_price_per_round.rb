class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePricePerRound
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless should_calculate_ppr?
        listing.price.per_round = calculate_price_per_round(listing.price.current)
      end

    end
  end
end