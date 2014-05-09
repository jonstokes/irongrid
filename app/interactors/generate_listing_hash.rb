class GenerateListingHash
  include Interactor

  def perform
    context[:item_data] = convert_es_objects_to_json
    context[:listing] = {
      "url"          => url,
      "digest"       => digest,
      "type"         => type,
      "item_data"    => item_data
    }
  end

  def convert_es_objects_to_json
    # convert title and keywords
    # convert everything in the metadata table
    # Make sure that category-inappropriate metadata is NOT included in the final hash
  end
end
