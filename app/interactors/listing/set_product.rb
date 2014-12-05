class SetProduct
  include Interactor

  def call
    return unless context.listing.product.try(:any?)
    context.listing.product_source = context.listing.product.dup

    return unless product = find_or_create_product || match_product
    context.listing.product = product.merge(context.listing.product)
  end

  def find_or_create_product
    product = FindOrCreateProduct.call(product_json: context.listing.product).product
    product.persisted? ? product : nil
  end

  def match_product
    MatchProduct.call(product_json: context.listing.product).product
  end
end
