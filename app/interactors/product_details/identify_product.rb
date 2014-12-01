module ProductDetails
  class IdentifyProduct
    include Interactor

    def call
      context.product = find_by_upc || find_by_mpn || find_by_sku || find_by_attributes
    end

    def find_by_upc
      return unless context.listing_json.product_upc.present?
      IronBase::Product.find_by_upc(context.listing_json.product_upc)
    end

    def find_by_mpn
      return unless context.listing_json.product_mpn.present?
      mpn = IronBase::Product.normalize(context.listing_json.product_mpn)
      products = IronBase::Product.find_by_mpn(mpn)
      products.hits.any? ? products.hits.first : nil
    end

    def find_by_sku
      return unless context.listing_json.product_sku.present?
      sku = IronBase::Product.normalize(context.listing_json.product_sku)
      products = IronBase::Product.find_by_sku(sku)
      products.hits.any? ? products.hits.first : nil
    end

    def find_by_attributes
      # Take existing captured product attrs, and try to match as many as
      # possible
      query_hash = {
          query: {
              filtered: {
                  filter: {
                      must: attribute_filters
                  }
              }
          }
      }
      return nil unless filters.size >= 3 # Match at least three attrs
      results = IronBase::Product.search(query_hash)
      results.hits.any? ? results.hits.first : nil
    end

    def attribute_filters
      # TODO: Use map
      filters = []
      context.listing_json.each do |k, v|
        next unless !!k[/product_/]
        next if %w(product_mpn product_sku product_upc).include?(k) || v.nil?
        attr = k.split('product_').last
        filters << { term: { attr => v } }
      end
      filters
    end

  end
end
