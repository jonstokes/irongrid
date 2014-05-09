class ParsePage
  include Interactor::Organizer

  organize [
    DecoratePage
    ExtractRawListingFromPage
    DetermineListingType
    CleanUpCommonListingAttributes
    CleanUpTypeSpecificListingAttributes
    ExtractMetaDataFromRawListing
    ExtractMetadataFromListingAttributes
    SoftCategorize
    GenerateDigest
  ]
end
