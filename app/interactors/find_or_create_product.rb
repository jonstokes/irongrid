class FindOrCreateProduct
  include Interactor

  def call
    context.product = IronBase::Product.find_by_upc if upc
    context.product ||= IronBase::Product.find_by_mpn(mpn).hits.first if mpn
    context.product ||= IronBase::Product.find_by_sku(sku).hits.first if sku
    context.product ||= IronBase::Product.new(
        upc: context.product_json.upc,
        mpn: context.product_json.mpn,
        sku: context.product_json.sku
    )
  end

  def upc
    return unless context.product_json.upc.present?
    context.product_json.upc
  end

  def mpn
    return unless context.product_json.mpn.present?
    IronBase::Product.normalize(context.product_json.mpn)
  end

  def sku
    return unless context.product_json.sku.present?
    IronBase::Product.normalize(context.product_json.sku)
  end
end