class SetProduct
  include Interactor

  def call
    context.listing.product = IronBase::DenormalizeProductForListing.call(product: context.product).product
  end
end