class ExtractMetadataFromSourceAttributes
  include Interactor

  def perform
    attributes_to_be_extracted.each do |attr|
      next if context[attr.to_sym].try(:raw)
      next if send("extract_#{attr}", context[:title])
      next unless keywords.raw
      send("extract_#{attr}", context[:keywords])
    end
    context[:title].normalized = ProductDetails.renormalize_all(title.normalized)
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

  def extract_caliber(field)
    normalized_content = ProductDetails::Caliber.analyze(field.scrubbed)
    results = ProductDetails::Caliber.parse(normalized_content)
    field.normalized = results[:text]
    context[:caliber] ||= ElasticSearchObject.new("caliber")
    context[:caliber].raw = results[:keywords].first
    context[:caliber_category].raw = results[:category]
  end

  def extract_manufacturer(field)
    normalized_content = ProductDetails::Manufacturer.analyze(field.normalized || field.scrubbed)
    results = ProductDetails::Manufacturer.parse(normalized_content)
    field.normalized = results[:text]
    context[:manufacturer] ||= ElasticSearchObject.new("manufacturer")
    context[:manufacturer].raw = results[:keywords].first
  end

  def extract_grains(field)
    results = ProductDetails::Grains.parse(field)
    field.normalized = results[:text]
    context[:grains] ||= ElasticSearchObject.new("grains")
    context[:grains].raw = results[:keywords].first
  end

  def extract_number_of_rounds(field)
    results = ProductDetails::Rounds.parse(field.normalized)
    field.normalized = results[:text]
    context[:number_of_rounds] ||= ElasticSearchObject.new("number_of_rounds")
    context[:number_of_rounds] = results[:keywords].first
  end
end
