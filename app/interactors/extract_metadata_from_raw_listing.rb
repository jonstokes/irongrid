class ExtractMetadataFromRawListing
  include Interactor

  def perform
    attributes.each do |attr|
      send("extract_#{attr}") if listing_json["product_#{attr}"]
    end
  end

  def attributes
    @attributes ||= (ProductDetails::Metadata.attributes_to_be_extracted(category1.raw) +
                     ['caliber_category']).map(&:to_s)
  end

  def extract_caliber
    str = ProductDetails::Scrubber.scrub(listing_json['product_caliber'], :punctuation, :caliber)
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
    str = ProductDetails::Scrubber.scrub(listing_json['product_caliber_category'], :punctuation, :caliber)
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
    str = ProductDetails::Scrubber.scrub(listing_json['product_manufacturer'], :punctuation)
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
    grains = listing_json['product_grains'].delete(",").to_i
    return unless grains > 0
    context[:grains] = ElasticSearchObject.new(
      "grains",
      raw: grains,
      classification_type: "hard"
    )
  end

  def extract_number_of_rounds
    rounds = listing_json['product_number_of_rounds'].delete(",").to_i
    return unless rounds > 0
    context[:number_of_rounds] = ElasticSearchObject.new(
      "number_of_rounds",
      raw: rounds,
      classification_type: "hard"
    )
  end
end
