class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateDiscountWithShipping
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless shipping_included? && discounted?

        with_shipping.merge!(
            discount: {
                in_cents: discount_in_cents,
                percent:  discount_percent
            }
        )
      end

      def discount_in_cents
        calculate_discount_in_cents(list_price, with_shipping.price.current)
      end

      def discount_percent
        calculate_discount_percent(list_price, with_shipping.price.current)
      end
    end
  end
end