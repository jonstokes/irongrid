class SetProduct
  include Interactor

  def call
    context.listing.product = denormalize_for_listing(context.product)
  end


end