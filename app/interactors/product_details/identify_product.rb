module ProductDetails
  class IdentifyProduct
    include Interactor

    def call
      context.fail! unless context.listing.product
      product = FindOrCreateProduct.call(context.listing.product)
      context.product = product.persisted? ? product : find_best_match
    end

    def find_best_match
      match_on_mpn || match_on_sku || match_on_attributes
    end

    def match_on_mpn
      # TODO: some sort of fuzzy match
    end

    def match_on_sku
      # TODO
    end

    def match_on_attributes
      # Take existing captured product attrs, and try to match as many as
      # possible
      return nil unless attribute_filters.size >= 3 # Use at least three attrs
      query_hash = {
          query: {
              filtered: {
                  filter: {
                      bool: {
                          must: attribute_filters,
                          minimum_should_match: 3
                      }
                  }
              }
          }
      }
      return nil unless attribute_filters.size >= 3 # Match at least three attrs
      results = IronBase::Product.search(query_hash)
      results.hits.any? ? results.hits.first : nil
    end

    def attribute_filters
      # TODO: Use map
      @attribute_filters ||= begin
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
end
