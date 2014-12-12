class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateShipping
      class CalculatePrice
        include Interactor

        def call
          context.with_shipping = Hashie::Mash.new(
              price: {
                  current: current_price_with_shipping,
                  list:    list_price_with_shipping,
                  sale:    sale_price_with_shipping
              }
          )
        end

        def current_price_with_shipping
          return unless context.price.current
          context.price.current + context.shipping.cost
        end

        def list_price_with_shipping
          return unless context.price.list
          context.price.list + context.shipping.cost
        end

        def sale_price_with_shipping
          return unless context.price.sale
          context.price.sale + context.shipping.cost
        end
      end
    end
  end
end