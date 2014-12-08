class MatchProduct
  include Interactor

  def call
    # This tries to match products with a looser mpn, sku, and attribute search.
    # Since the out put of this interactor only fills in listing metadata, and will never
    # write to the canonical Product index, it's ok if it's less accurate.

    context.fail! unless context.product_json.present?
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
    return nil unless attribute_filters.size >= 4 # Use at least three attrs plus engine
    query_hash = {
        query: {
            filtered: {
                filter: {
                    bool: { should: attribute_filters }
                }
            }
        }
    }
    results = IronBase::Product.search(query_hash)
    results.hits.any? ? results.hits.first : nil
  end

  def attribute_filters
    # TODO: Use map
    @attribute_filters ||= begin
      filters = []
      context.product_json.each do |k, v|
        next if %w(mpn sku upc long_description weight image name image_download_attempted image_cdn).include?(k) || v.nil?
        filters << { term: { k => v } }
      end
      filters
    end
  end

end

