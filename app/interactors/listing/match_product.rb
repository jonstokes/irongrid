class MatchProduct
  include Interactor

  def call
    return unless context.product
    context.product = match_product_by_attributes || IronBase::Product.new
    context.product.import_from_listing!(context.listing) # Merge original captured attrs back in
  end

  def match_product_by_attributes
    MatchProduct.call(listing: context.listing).product
  end
end
