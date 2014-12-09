class WriteListingToIndex
  include Interactor::Organizer

  # Expect context to have site, page, listing_json

  organize [
    SetUrl,
    FindOrCreateListing,
    MergeJsonIntoListing,
    UpdateAndSetProduct,
    RunLoadableScripts,
    SetListingDigest,
    LinkDenormalizedLocation,
    UpdateListingImage,
    SaveListingToIndex
  ]
end