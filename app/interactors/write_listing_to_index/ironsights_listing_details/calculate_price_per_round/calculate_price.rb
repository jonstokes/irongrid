class WriteListingToIndex
  class IronsightsListingDetails
    class CalculatePricePerRound
      class PricePerRound
        include Interactor

        def call
          context.price_per_round ||=
              (context.price.current.to_f / context.number_of_rounds.to_f).round.to_i
        end
      end
    end
  end
end