class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePricePerRound
      class Discount
        include Interactor

        def call
          return unless context.list_ppr
          context.discount_ppr_percent = calculate_discount_percent(context.list_ppr, context.price_per_round)
        end

        def calculate_discount_percent(list_price, sale_price)
          return 0 unless (list_price > sale_price) && !sale_price.zero?
          (list_price.to_f / sale_price.to_f).round * 100
        end
      end
    end
  end
end