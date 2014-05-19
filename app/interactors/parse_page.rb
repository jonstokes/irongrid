class ParsePage
  include Interactor::Organizer

  # Expect context to have site, adapter_type, page, url

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


