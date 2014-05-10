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
      next if context[attr.to_sym].raw || send("extract_#{attr}", :title)
      next keywords.raw.nil?
      send("extract_#{attr}", :keywords)
    end
    context[:title].normalized = ProductDetails::renormalize_all(title.normalized)
  end

  def extract_caliber(field_name)
    normalized_content = ProductDetails::Caliber.analyze(context[field_name].scrubbed)
    results = ProductDetails::Caliber.parse(normalized_content)
    context[field_name].normalized = results[:text]
    context[:caliber].raw = results[:keywords].first
    context[:caliber_category].raw = results[:category]
  end

  def extract_manufacturer(field_name)
    normalized_content = ProductDetails::Manufacturer.analyze(title.normalized || title.scrubbed)
    results = ProductDetails::Manufacturer.parse(normalized_content)
    context[field_name].normalized = results[:text]
    context[:manufacturer.raw] = results[:keywords].first
  end

  def extract_grains(field_name)
    results = ProductDetails::Grains.parse(title.normalized)
    context[field_name].normalized = results[:text]
    context[:grains].raw = results[:keywords].first
  end

  def extract_number_of_rounds(field_name)
    results = ProductDetails::Rounds.parse(title.normalized)
    context[field_name].normalized = results[:text]
    context[:number_of_rounds] = results[:keywords].first
  end
end
