class ParsePage
  include Interactor::Organizer

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
    SetPricePerRound,
    SoftCategorize,
    SetDigest,
    GenerateListingHash
  ]

  def is_valid?
    success?
  end

  def not_found?
    !success? && status == :not_found
  end
end


