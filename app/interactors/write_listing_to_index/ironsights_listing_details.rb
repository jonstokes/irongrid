class WriteListingToIndex
  class IronsightsListingDetails
    include Interactor::Organizer

    organize CalculateDiscount,
             CalculatePriceWithShipping,
             CalculateDiscountWithShipping,
             CalculatePricePerRound,
             CalculatePricePerRoundWithShipping,
             CalculateDiscountPprPercent,
             CalculateDiscountPprPercentWithShipping
  end
end