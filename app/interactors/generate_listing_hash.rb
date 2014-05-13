class GenerateListingHash
  include Interactor

  def perform
    context[:listing] = {
      "url"          => url,
      "digest"       => digest,
      "type"         => type,
      "item_data"    => generate_item_data
    }
  end

  def generate_item_data
    item_data_hash = {}
    (Listing::ITEM_DATA_ATTRIBUTES + Listing::ES_OBJECTS).each do |attr|
      attribute = attr.to_sym
      if context[attribute].is_a?(ElasticSearchObject)
        item_data_hash.merge!(attr => context[attribute].to_a)
      else
        item_data_hash.merge!(attr => context[attribute])
      end
    end
    item_data_hash
  end
end
