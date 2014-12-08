class SetProduct
  include Interactor

  before do
    context.listing.product_source ||= {}
  end

  def call
    return unless product = find_product || match_product_by_attributes
    product.merge!(context.listing.product_source) # Merge original captured attrs back in
    context.listing.product = product.normalized_for_listing
  end

  def find_product
    product = FindOrCreateProduct.call(product_json: context.listing.product_source).product
    product.try(:persisted?) ? product : nil
  end

  def match_product_by_attributes
    MatchProduct.call(product_json: context.listing.product_source).product
  end
end
