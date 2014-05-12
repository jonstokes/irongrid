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
end


