class SetProduct
  include Interactor

  def call
    return unless product = find_product || match_product
    context.listing.product = product.merge(context.listing.product)
    context.listing.product_source.reject! do |key, value|
      context.listing.product[key] == context.product_source[key]
    end
  end

  def find_product
    product = FindOrCreateProduct.call(product_json: context.listing.product).product
    product.persisted? ? product : nil
  end

  def match_product
    MatchProduct.call(product_json: context.listing.product).product
  end
end

# This is all tangled up. I need to be copying everything once and pulling it over!