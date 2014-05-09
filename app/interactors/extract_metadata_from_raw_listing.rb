class ExtractMetaDataFromRawListing
  include Interactor

  def setup
    context[:metadata] = MetadataTable.new
  end

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
    context[:metadata].update(
      attribute: :caliber,
      source:    :raw,
      content:   results[:keywords].first
    )
    context[:metadata].update(
      attribute: :caliber_category,
      source:    :raw,
      content:   results[:category])
  end

  def extract_caliber_category
    str = ProductDetails::Scrubber.scrub(raw_listing['caliber_category'], :punctuation, :caliber)
    str = ProductDetails::Caliber.analyze(str)
    results = ProductDetails::Caliber.parse_category(str)
    context[:metadata].update(
      attribute: :caliber_category,
      source:    :raw,
      content:   results[:keywords].first
    )
  end

  def extract_manufacturer
    str = ProductDetails::Scrubber.scrub(raw_listing['manufacturer'], :punctuation)
    str = ProductDetails::Manufacturer.analyze(str)
    results = ProductDetails::Manufacturer.parse(str)
    context[:metadata].update(
      attribute: :manufacturer,
      source:    :raw,
      content:   results[:keywords].first
    )
  end

  def extract_grains
    context[:metadata].update(
      attribute: :grains,
      source:    :raw,
      content:   raw_listing['grains'].delete(",").to_i
    )
  end

  def extract_number_of_rounds
    context[:metadata].update(
      attribute: :number_of_rounds,
      source:    :raw,
      content:   raw_listing['number_of_rounds'].delete(",").to_i
    )
  end
end
