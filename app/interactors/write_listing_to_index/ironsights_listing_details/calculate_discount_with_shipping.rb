class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateDiscountWithShipping
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless shipping_included? && discounted?

        with_shipping.merge!(
            discount: {
                in_cents: calculate_discount_in_cents(listing.price.list, with_shipping.price.current),
                percent:  calculate_discount_percent(listing.price.list, with_shipping.price.current)
            }
        )
      end

    end
  end
end