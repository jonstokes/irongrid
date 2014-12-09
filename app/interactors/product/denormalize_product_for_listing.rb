class DenormalizeProductForListing
  include Interactor

  def call
    context.denormalized_product = {}
    IronBase::Listing.mapping.listing.properties.product_source.properties.each_key do |field|
      context.denormalized_product.merge!(field => context.product.send(field))
    end
  end
end