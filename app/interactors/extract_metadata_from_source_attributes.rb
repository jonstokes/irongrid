class ExtractMetadataFromSourceAttributes
  include Interactor

  def perform
    attributes_to_be_extracted.each do |attr|
      next if context[attr.to_sym].try(:raw)
      next if extract_attribute(:title, attr)
      extract_attribute(:keywords, attr)
    end
    context[:title].normalized = ProductDetails.renormalize_all(title.normalized)
  end

  def extract_attribute(field, attr)
    source_content = context[field].normalized || context[field].scrubbed
    send("extract_#{attr}", field, source_content)
    !!context[attr.to_sym].try(:raw)
  end

  def attributes_to_be_extracted
    case category1
    when "Optics"
      MetadataTable::OPTICS_METADATA_ATTRIBUTES
    when "Guns"
      MetadataTable::GUN_METADATA_ATTRIBUTES
    else
      MetadataTable::AMMO_METADATA_ATTRIBUTES
    end
  end

  def extract_caliber(field_name, source_content)
    normalized_content = ProductDetails::Caliber.analyze(source_content)
    results = ProductDetails::Caliber.parse(normalized_content)
    context[field_name].normalized = results[:text]
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
    context[:manufacturer] = ElasticSearchObject.new(
      "manufacturer",
      raw: results[:keywords].first,
      classification_type: "metadata"
    )
  end

  def extract_grains(field_name, source_content)
    results = ProductDetails::Grains.parse(source_content)
    context[field_name].normalized = results[:text]
    context[:grains] = ElasticSearchObject.new(
      "grains",
      raw: results[:keywords].first,
      classification_type: "metadata"
    )
  end

  def extract_number_of_rounds(field_name, source_content)
    results = ProductDetails::Rounds.parse(source_content)
    context[field_name].normalized = results[:text]
    context[:number_of_rounds] = ElasticSearchObject.new(
      "number_of_rounds",
      raw: results[:keywords].first,
      classification_type: "metadata"
    )
  end
end
