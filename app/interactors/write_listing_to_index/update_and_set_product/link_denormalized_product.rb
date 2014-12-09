class LinkDenormalizedProduct
  include Interactor

  def call
    context.listing.product = IronBase::DenormalizeProductForListing.call(product: context.product).denormalized_product
  end
end