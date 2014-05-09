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
    SetPricePerRound,
    ScrubMetaDataSourceAttributes,
    ExtractMetaDataFromRawListing,
    ExtractMetadataFromSourceAttributes,
    SoftCategorize,
    SetDigest,
    GenerateListingHash
  ]
end


