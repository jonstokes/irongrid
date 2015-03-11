class WriteListingToIndex
  class LinkDenormalizedProduct
    include Interactor

    def call
      # FIXME: All loadables are using context.product
      context.listing.product = IronBase::DenormalizeProductForListing.call(product: context.product).denormalized_product
    end
  end
end