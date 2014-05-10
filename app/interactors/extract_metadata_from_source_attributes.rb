class ExtractMetadataFromSourceAttributes
  include Interactor

  def perform
    attributes_to_be_extracted = case type
      when "Optics"
        MetadataTable::OPTICS_METADATA_ATTRIBUTES
      when "Guns"
        MetadataTable::GUN_METADATA_ATTRIBUTES
      else
        MetadataTable::AMMO_METADATA_ATTRIBUTES
      end

    attributes_to_be_extracted.each do |attr|
      send("extract_#{attr}", :title)
      send("extract_#{attr}", :keywords)
    end
    metadata_source_attrs[:title][:normalized] = ProductDetails::renormalize_all(metadata_source_attrs[:title][:normalized])
  end

  def extract_caliber(field_name)
    return unless scrubbed_content = metadata_source_attrs[field_name][:scrubbed] rescue nil
    normalized_content = ProductDetails::Caliber.analyze(scrubbed_content)
    results = ProductDetails::Caliber.parse(normalized_content)
    context[:metadata_source_attrs][field_name][:normalized] = results[:text]
    context[:metadata].update(attribute: :caliber, source: field_name, content: results[:keywords].first)
    context[:metadata].update(attribute: :caliber_category, source: field_name, content: results[:category])
  end

  def extract_manufacturer
    normalized[field_name] = ProductDetails::Manufacturer.analyze(normalized[field_name] || scrubbed[field_name])
    results = ProductDetails::Manufacturer.parse(normalized[field_name])
    normalized[field_name] = results[:text]
    context[:metadata].update(attribute: :manufacturer, source: field_name, content: results[:keywords].first)
  end

  def extract_grains
    results = ProductDetails::Grains.parse(normalized[field_name])
    normalized[field_name] = results[:text]
    context[:metadata].update(attribute: :grains, source: field_name, content: results[:keywords].first)
  end

  def extract_number_of_rounds
    results = ProductDetails::Rounds.parse(normalized[field_name])
    normalized[field_name] = results[:text]
    context[:metadata].update(attribute: :number_of_rounds, source: field_name, content: results[:keywords].first)
  end
end
