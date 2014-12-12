class IronsightsListingDetails
  class CalculatePricePerRound
    include Interactor::Organizer

    organize WithShipping, Discount, DiscountWithShipping

  end
end