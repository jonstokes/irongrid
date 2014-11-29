class FindOrCreateProduct
  include Interactor

  def call
    context.product = IronBase::Product.find_by_upc if context.upc
    context.product ||= IronBase::Product.find_by_mpn(mpn).hits.first if mpn
    context.product ||= IronBase::Product.find_by_sku(sku).hits.first if sku
    context.product ||= IronBase::Product.new(
        upc: context.upc,
        mpn: context.mpn,
        sku: context.sku
    )
  end

  def mpn
    return unless context.mpn.present?
    IronBase::Product.normalize(context.mpn)
  end

  def sku
    return unless context.sku.present?
    IronBase::Product.normalize(context.sku)
  end
end