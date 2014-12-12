class WriteListingToIndex
  class IronsightsListingDetails
    include Interactor::Organizer

    organize CalculatePriceWithShipping,
             CalculateDiscountWithShipping,
             CalculatePricePerRound,
             CalculatePricePerRoundWithShipping,
             CalculateDiscountPprPercent,
             CalculateDiscountPprPercentWithShipping
  end
end