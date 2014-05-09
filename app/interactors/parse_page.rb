class ParsePage
  include Interactor::Organizer

  # Expect context to have site, adapter_type, page

  organize [
    DecoratePage,
    ExtractRawListingFromPage,
    ValidateListingPresence,
    DetermineListingType,
    ValidateListing,
    CleanUpCommonListingAttributes,
    CleanUpPriceAttributes,
    SetCurrentPrice,
    ScrubMetaDataSourceAttributes,
    ExtractMetaDataFromRawListing,
    ExtractMetadataFromSourceAttributes,
    SoftCategorize,
    GenerateDigest
  ]
end
