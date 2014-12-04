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
    hits = prune_hits(hits)
    order_hits_by_best_match(hits).first
  end

  def find_by_sku
    return unless context.product_json.sku.present?
    hits = IronBase::Product.find_by_sku(context.product_json.sku)
    hits = prune_hits(hits)
    order_hits_by_best_match(hits).first
  end

  def prune_hits(hits)
    hits.select! do |hit|
      hit.category1.nil? || (hit.category1 == context.product_json.category1)
    end if context.product_json.category1

    hits.select! do |hit|
      hit.manufacturer.nil? || (hit.manufacturer == context.product_json.manufacturer)
    end if context.product_json.manufacturer

    hits.select! do |hit|
      hit.caliber_category.nil? || (hit.caliber_category == context.product_json.caliber_category)
    end if context.product_json.caliber_category

    hits
  end

  def order_hits_by_best_match(hits)
    scored_hits = hits.map { |hit| { hit: hit, score: score(hit) } }
    scored_hits.sort! { |a, b| b[:score] <=> a[:score] }
    scored_hits.map { |hit| hit[:hit] }
  end

  def score(hit)
    count = 0
    hit.send(:data_in_index_format).each do |k, v|
      count += 1 if context.product_json[k] == v
    end
    count
  end
end