class MergeJsonIntoProduct
  include Interactor

  def call
    return if context.product.complete?
    context.product.mpn = context.product_json.mpn
    context.product.sku = context.product_json.sku
    context.product.weight ||= { shipping: context.product_json.weight }
    context.product.image ||= { source: context.product_json.image_source}
    IronBase::Product.properties.except(:mpn, :sku, :weight, :image).each do |attr|
      context.product[attr] ||= context.product_json[attr]
    end
    context.product.save
  end

end