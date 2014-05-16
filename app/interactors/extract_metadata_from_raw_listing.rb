class ExtractMetadataFromRawListing
  include Interactor
  METADATA_ATTRIBUTES = [:caliber, :caliber_category, :manufacturer, :grains, :number_of_rounds]

  AMMO_METADATA_ATTRIBUTES = 
  GUN_METADATA_ATTRIBUTES = 
  OPTICS_METADATA_ATTRIBUTES = %w(manufacturer)

  def perform
    attributes_to_be_extracted.each do |attr|
      send("extract_#{attr}") if raw_listing[attr]
    end
  end

  def attributes_to_be_extracted
    if category1.raw == "None"
      (ParsePage::CATEGORY1_VALID_ATTRIBUTES["Ammunition"] + [:caliber_category]).map(&:to_s)
    else
      (ParsePage::CATEGORY1_VALID_ATTRIBUTES[category1.raw] + [:caliber_category]).map(&:to_s)
    end
  end

  def extract_caliber
    str = ProductDetails::Scrubber.scrub(raw_listing['caliber'], :punctuation, :caliber)
    str = ProductDetails::Caliber.analyze(str)
    results = ProductDetails::Caliber.parse(str)
    return unless results[:keywords].first
    context[:caliber] = ElasticSearchObject.new(
      "caliber",
      raw: results[:keywords].first,
      classification_type: "hard"
    )
    context[:caliber_category] = ElasticSearchObject.new(
      "caliber_category",
      raw: results[:category],
      classification_type: "hard"
    )
  end

  def extract_caliber_category
    str = ProductDetails::Scrubber.scrub(raw_listing['caliber_category'], :punctuation, :caliber)
    str = ProductDetails::Caliber.analyze(str)
    results = ProductDetails::Caliber.parse_category(str)
    return unless results[:keywords].first
    context[:caliber_category] = ElasticSearchObject.new(
      "caliber_category",
      raw: results[:keywords].first,
      classification_type: "hard"
    )
  end

  def extract_manufacturer
    str = ProductDetails::Scrubber.scrub(raw_listing['manufacturer'], :punctuation)
    str = ProductDetails::Manufacturer.analyze(str)
    results = ProductDetails::Manufacturer.parse(str)
    return unless results[:keywords].first
    context[:manufacturer] = ElasticSearchObject.new(
      "manufacturer",
      raw: results[:keywords].first,
      classification_type: "hard"
    )
  end

  def extract_grains
    grains = raw_listing['grains'].delete(",").to_i
    return unless grains > 0
    context[:grains] = ElasticSearchObject.new(
      "grains",
      raw: grains,
      classification_type: "hard"
    )
  end

  def extract_number_of_rounds
    rounds = raw_listing['number_of_rounds'].delete(",").to_i
    return unless rounds > 0
    context[:number_of_rounds] = ElasticSearchObject.new(
      "number_of_rounds",
      raw: rounds,
      classification_type: "hard"
    )
  end
end
