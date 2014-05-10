class ExtractMetaDataFromRawListing
  include Interactor

  def perform
    attributes_to_be_extracted = case type
      when "Optics"
        MetadataTable::OPTICS_METADATA_ATTRIBUTES + 'caliber_category'
      when "Guns"
        MetadataTable::GUN_METADATA_ATTRIBUTES + 'caliber_category'
      else
        MetadataTable::AMMO_METADATA_ATTRIBUTES
      end

    attributes_to_be_extracted.each do |attr|
      send("extract_#{attr}") if raw_listing[attr]
    end
  end

  def extract_caliber
    str = ProductDetails::Scrubber.scrub(raw_listing['caliber'], :punctuation, :caliber)
    str = ProductDetails::Caliber.analyze(str)
    results = ProductDetails::Caliber.parse(str)
    context[:caliber] = ElasticSearchObject.new(
      "caliber",
      raw: results[:keywords].first
    )
    context[:caliber_category] = ElasticSearchObject.new(
      "caliber_category",
      raw: results[:category]
    )
  end

  def extract_caliber_category
    str = ProductDetails::Scrubber.scrub(raw_listing['caliber_category'], :punctuation, :caliber)
    str = ProductDetails::Caliber.analyze(str)
    results = ProductDetails::Caliber.parse_category(str)
    context[:caliber_category] = ElasticSearchObject.new(
      "caliber_category",
      raw: results[:keywords].first
    )
  end

  def extract_manufacturer
    str = ProductDetails::Scrubber.scrub(raw_listing['manufacturer'], :punctuation)
    str = ProductDetails::Manufacturer.analyze(str)
    results = ProductDetails::Manufacturer.parse(str)
    context[:manufacturer] = ElasticSearchObject.new(
      "manufacturer",
      raw: results[:keywords].first
    )
  end

  def extract_grains
    context[:grains] = ElasticSearchObject.new(
      "grains",
      raw: raw_listing['grains'].delete(",").to_i
    )
  end

  def extract_number_of_rounds
    context[:number_of_rounds] = ElasticSearchObject.new(
      "number_of_rounds",
      raw: raw_listing['number_of_rounds'].delete(",").to_i
    )
  end
end
