class MergeJsonIntoProduct
  include Interactor

  def call
    return if context.product.complete?
    context.product.mpn = context.product_json.mpn
    context.product.sku = context.product_json.sku
    IronBase::Product.properties.except(:mpn, :sku).each do |attr|
      context.product[attr] ||= context.product_json[attr]
    end
    context.product.save
  end

end