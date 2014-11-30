class FindOrCreateProduct
  include Interactor

  def call
    return unless context.product_json.upc.present? # We have to have a UPC
    context.product = find_by_upc ||
        find_by_mpn ||
        find_by_sku ||
        IronBase::Product.new(upc: context.product_json.upc)
  end

  def find_by_upc
    IronBase::Product.find_by_upc(context.product_json.upc)
  end

  def find_by_mpn
    return unless context.product_json.mpn.present?
    IronBase::Product.find_by_mpn(context.product_json.mpn).hits.first
  end

  def find_by_sku
    return unless context.product_json.sku.present?
    IronBase::Product.find_by_sku(context.product_json.sku).hits.first
  end

end