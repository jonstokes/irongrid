class ParsePage
  include Interactor::Organizer

  CATEGORY1_VALID_ATTRIBUTES = {
    "Optics" => [:manufacturer],
    "Guns" => [:caliber, :manufacturer],
    "Ammunition" => [:caliber, :manufacturer, :grains, :number_of_rounds],
    "Accessories" => [:caliber, :manufacturer, :number_of_rounds],
    "None" => [:caliber, :manufacturer]
  }

  # Expect context to have site, adapter_type, page
  organize [
    DecoratePage,
    ExtractRawListingFromPage,
    ValidateListingPresence,
    DetermineListingType,
    ValidateListing,
    SetCommonAttributes,
    SetPriceAttributes,
    SetAvailability,
    SetCurrentPrice,
    ScrubMetadataSourceAttributes,
    ExtractMetadataFromRawListing,
    ExtractMetadataFromSourceAttributes,
    SoftCategorize,
    SetPricePerRound,
    SetDigest,
    GenerateListingHash
  ]

  def is_valid?
    success?
  end

  def not_found?
    !success? && status == :not_found
  end

  def classified_sold?
    !success? && status == :classified_sold
  end
end


