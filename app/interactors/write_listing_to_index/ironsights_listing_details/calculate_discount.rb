class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateDiscount
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return if discounted? || !list_price

        listing.discount = {
            in_cents: discount_in_cents,
            percent:  discount_percent
        }
      end

      def discount_in_cents
        calculate_discount_in_cents(list_price, listing.price.current)
      end

      def discount_percent
        calculate_discount_percent(list_price, listing.price.current)
      end
    end
  end
end