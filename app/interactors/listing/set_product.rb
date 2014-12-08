class SetProduct
  include Interactor

  def call
    unless context.product
      context.product = match_product_by_attributes || IronBase::Product.new
      context.product.import_from_listing(context.listing) # Merge original captured attrs back in
    end
    context.listing.product = context.product.normalized_for_listing
  end

  def match_product_by_attributes
    MatchProduct.call(product_json: context.listing.product_json).product
  end
end
