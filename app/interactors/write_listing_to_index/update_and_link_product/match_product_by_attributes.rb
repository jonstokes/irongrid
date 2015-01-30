class WriteListingToIndex
  class UpdateAndLinkProduct
    class MatchProductByAttributes
      include Interactor

      before do
        context.product = nil unless context.product.try(:persisted?)
      end

      def call
        # This tries to match products with a looser mpn, sku, and attribute search.
        # Since the out put of this interactor only fills in listing metadata, and will never
        # write to the canonical Product index, it's ok if it's less accurate.
        context.product ||= match_on_mpn ||
            match_on_sku ||
            match_on_attributes ||
            IronBase::Product.new
      end

      def product_source
        context.listing.product_source
      end

      def match_on_mpn
        return unless product_source.present? && product_source.any?
        # TODO: some sort of fuzzy match
      end

      def match_on_sku
        return unless product_source.present? && product_source.any?
        # TODO: some sort of fuzzy match
      end

      def match_on_attributes
        return unless product_source.present? && product_source.any?
        # Take existing captured product attrs, and try to match as many as
        # possible
        return nil unless attribute_filters.size >= 4 # Use at least three attrs plus engine
        q = IronBase::Document::Search.new(
            query_hash: {
                query: {
                    filtered: {
                        filter: {
                            bool: { should: attribute_filters }
                        }
                    }
                }
            }
        )
        results = IronBase::Product.search(q)
        results.hits.any? ? results.hits.first : nil
      end

      def attribute_filters
        # TODO: Use map
        @attribute_filters ||= begin
          filters = []
          product_source.each do |k, v|
            next if %w(mpn sku upc long_description weight image name image_download_attempted image_cdn).include?(k) || v.nil?
            filters << { term: { k => v } }
          end
          filters
        end
      end

    end
  end
end