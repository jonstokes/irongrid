class FindOrCreateProduct
  include Interactor

  before do
    context.listing.product_source ||= Hashie::Mash.new
  end

  def call
    # This tries to find a product with a pretty strict usage of normalized UPC, MPN, and SKU
    context.product ||= find_by_upc ||
                        find_by_mpn ||
                        find_by_sku ||
                        IronBase::Product.new
  end

  def product_source
    context.listing.product_source
  end

  def find_by_upc
    return unless product_source.upc.present?
    IronBase::Product.find_by_upc(product_source.upc).first
  end

  def find_by_mpn
    return unless product_source.mpn.present?
    hits = IronBase::Product.find_by_mpn(product_source.mpn)
    hits = prune_hits(hits)
    order_hits_by_best_match(hits).first
  end

  def find_by_sku
    return unless product_source.sku.present?
    hits = IronBase::Product.find_by_sku(product_source.sku)
    hits = prune_hits(hits)
    order_hits_by_best_match(hits).first
  end

  def prune_hits(hits)
    hits.select! do |hit|
      hit.category1.nil? || (hit.category1 == product_source.category1)
    end if product_source.category1

    hits.select! do |hit|
      hit.manufacturer.nil? || (hit.manufacturer == product_source.manufacturer)
    end if product_source.manufacturer

    hits.select! do |hit|
      hit.caliber_category.nil? || (hit.caliber_category == product_source.caliber_category)
    end if product_source.caliber_category

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
      count += 1 if product_source[k] == v
    end
    count
  end
end