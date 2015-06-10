class WriteProductToIndex
  class FindOrCreateProduct
    include Interactor

    before do
      context.listing.product_source ||= Hashie::Mash.new
    end

    def call
      # This tries to find a product with a pretty strict usage of normalized UPC
      context.product ||=
              find_by_upc ||
              find_by_mpn ||
              IronBase::Product.new
    end

    def product_source
      context.listing.product_source
    end

    def find_by_upc
      return unless product_source['upc'].present?
      IronBase::Product.find_by_upc(product_source['upc']).first
    end

    def find_by_mpn
      return unless product_source['mpn'].present?
      hits = IronBase::Product.find_by_mpn(product_source['mpn']) +
        IronBase::Product.find_by_upc(product_source['mpn'])
      return unless hits.any?

      hits = prune_hits(hits)
      order_hits_by_best_match(hits).first
    end

    def prune_hits(hits)
      hits.select! do |hit|
        (hit.category1 == product_source['category1']) &&
          (hit.manufacturer == product_source['manufacturer']) &&
          (hit.caliber == product_source['caliber'])
      end
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
end
