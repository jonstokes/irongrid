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

    after do
      context.listing.price = nil if context.listing.price.empty?
      context.product.weight = nil if context.product.weight.empty?
      context.listing.shipping = nil if context.listing.shipping.empty?
    end

  end
end