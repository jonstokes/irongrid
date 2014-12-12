class WriteListingToIndex
  class IronsightsListingDetails
    class CalculateShipping
      class CalculateDiscount
        include Interactor

        def call
          return if context.discount.nil? || context.discount.zero?
          context.with_shipping.merge!(
              discount: {
                  in_cents: calculate_discount_in_cents(context.price.list, context.with_shipping.price.current),
                  percent:  calculate_discount_percent(context.price.list, context.with_shipping.price.current)
              }
          )
        end

        def calculate_discount_in_cents(list_price, sale_price)
          return 0 unless list_price > sale_price
          list_price - sale_price
        end

        def calculate_discount_percent(list_price, sale_price)
          return 0 unless (list_price > sale_price) && !sale_price.zero?
          (list_price.to_f / sale_price.to_f).round * 100
        end

      end
    end
  end
end