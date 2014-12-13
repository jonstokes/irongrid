class WriteListingToIndex
  class IronsightsListingDetails
    include Interactor::Organizer

    before do
      # Interactors will blow up if these are nil
      context.listing.price ||= {}
      context.product.weight ||= {}
    end

    organize CalculateDiscount,
             CalculatePriceWithShipping,
             CalculateDiscountWithShipping,
             CalculatePricePerRound,
             CalculatePricePerRoundWithShipping,

    after do
      context.listing.price = nil if context.listing.price.empty?
      context.product.weight = nil if context.product.weight.empty?
      context.listing.shipping = nil if context.listing.shipping.empty?
    end

  end
end