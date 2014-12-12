class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePricePerRound
      class CalculatePrice
        include Interactor

        def call
          context.price_per_round ||=
              (context.price.to_f / context.number_of_rounds.to_f).round.to_i
        end
      end
    end
  end
end