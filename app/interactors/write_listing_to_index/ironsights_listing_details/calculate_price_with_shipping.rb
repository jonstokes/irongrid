class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePriceWithShipping
      include Interactor
      include Ironsights::ListingCalculations

      def call
        return unless shipping_included?
        listing.with_shipping = {
            price: {
                current: current_price_with_shipping,
                list:    list_price_with_shipping,
                sale:    sale_price_with_shipping
            }
        }
      end

      def current_price_with_shipping
        return unless listing.price.current
        listing.price.current + shipping_cost
      end

      def list_price_with_shipping
        return unless listing.price.list
        listing.price.list + shipping_cost
      end

      def sale_price_with_shipping
        return unless listing.price.sale
        listing.price.sale + shipping_cost
      end

    end
  end
end
