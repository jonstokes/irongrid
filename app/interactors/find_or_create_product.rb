class FindOrCreateProduct
  include Interactor

  def call
    context.fail! unless context.product_json.upc.present? # We have to have a UPC
    context.product = find_by_upc ||
        find_by_mpn ||
        find_by_sku ||
        IronBase::Product.new(upc: context.product_json.upc)
  end

  def find_by_upc
    IronBase::Product.find_by_upc(context.product_json.upc).first
  end

  def find_by_mpn
    return unless context.product_json.mpn.present?
    hits = IronBase::Product.find_by_mpn(context.product_json.mpn)
    prune_hits(hits)
  end

  def find_by_sku
    return unless context.product_json.sku.present?
    hits = IronBase::Product.find_by_sku(context.product_json.sku)
    prune_hits(hits)
  end

  def prune_hits(hits)
    hits.select! { |hit| hit.category1 == context.product_json.category1 } if context.product_json.category1
    hits.select! { |hit| hit.caliber_category == context.product_json.caliber_category } if context.product_json.caliber_category
    hits.select! { |hit| hit.manufacturer == context.product_json.manufacturer } if context.product_json.manufacturer
    hits
  end
end