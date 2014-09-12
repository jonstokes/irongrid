module ProductDetails
  class ExtractMetadataFromSourceAttributes
    include Interactor

    def perform
      ProductDetails::Metadata.attributes_to_be_extracted(category1.raw).each do |attr|
        extract_attribute(:title, attr)
        extract_attribute(:keywords, attr) if context[:keywords].try(:raw)
      end
      context[:title].normalized = ProductDetails.renormalize_all(title.normalized)
    end

    def extract_attribute(field, attr)
      return unless source_content = context[field].normalized || context[field].scrubbed
      send("extract_#{attr}", field, source_content)
      !!context[attr].try(:raw)
    end

    def extract_caliber(field_name, source_content)
      normalized_content = ProductDetails::Caliber.analyze(source_content)
      results = ProductDetails::Caliber.parse(normalized_content)
      context[field_name].normalized = results[:text]
      return if context[:caliber].try(:raw) || !results[:keywords].first
      context[:caliber] = ElasticSearchObject.new(
        "caliber",
        raw: results[:keywords].first,
        classification_type: "metadata"
      )
      context[:caliber_category] = ElasticSearchObject.new(
        "caliber_category",
        raw: results[:category],
        classification_type: "metadata"
      )
    end

    def extract_manufacturer(field_name, source_content)
      normalized_content = ProductDetails::Manufacturer.analyze(source_content)
      results = ProductDetails::Manufacturer.parse(normalized_content)
      context[field_name].normalized = results[:text]
      return if context[:manufacturer].try(:raw) || !results[:keywords].first
      context[:manufacturer] = ElasticSearchObject.new(
        "manufacturer",
        raw: results[:keywords].first,
        classification_type: "metadata"
      )
    end

    def extract_grains(field_name, source_content)
      results = ProductDetails::Grains.parse(source_content)
      context[field_name].normalized = results[:text]
      return if context[:grains].try(:raw) || !results[:keywords].first
      context[:grains] = ElasticSearchObject.new(
        "grains",
        raw: results[:keywords].first,
        classification_type: "metadata"
      )
    end

    def extract_number_of_rounds(field_name, source_content)
      results = ProductDetails::Rounds.parse(source_content)
      context[field_name].normalized = results[:text]
      return if context[:number_of_rounds].try(:raw) || !results[:keywords].first
      context[:number_of_rounds] = ElasticSearchObject.new(
        "number_of_rounds",
        raw: results[:keywords].first,
        classification_type: "metadata"
      )
    end
  end
end
