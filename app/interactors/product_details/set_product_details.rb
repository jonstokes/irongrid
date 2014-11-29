module ProductDetails
  class SetProductDetails
    include Interactor

    def call
      return unless context.product || context.products
      product = context.product.to_hash if context.product
      product ||= {
          engine: context.listing.engine,
          name: product_attribute(:name),
          short_description: product_attribute(:short_description),
          long_description: product_attribute(:long_description),
          image: product_attribute(:image),
          msrp: product_attribute(:msrp),
          category1: product_attribute(:category1),
          mpn: product_attribute(:mpn),
          upc: product_attribute(:upc),
          sku: product_attribute(:sku),
          manufacturer: product_attribute(:manufacturer),
          caliber: product_attribute(:caliber),
          caliber_category: product_attribute(:caliber_category),
          number_of_rounds: product_attribute(:number_of_rounds),
          grains: product_attribute(:grains)
      }
      # This won't work. Also, weight is missing!
      context.listing.product = product
    end

    def aggs
      @aggs ||= Hashie::Mash.new(context.products.aggregations)
    end

    def product_attribute(attr)
      aggs[attr].buckets.sort! { |a, b| a.doc_count <=> b.doc_count }
      aggs[attr].buckets.first.key
    end
  end
end
