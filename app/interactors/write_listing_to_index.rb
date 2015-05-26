class WriteListingToIndex
  include Interactor::Organizer

  # Expect context to have site, page, listing_json

  organize [
    FindOrCreateListing,
    MergeJsonIntoListing,
    WriteProductToIndex,
    UpdateListingFromProduct,
    RunLoadableScripts,
    SetListingDigest,
    LinkDenormalizedLocation,
    UpdateListingImage,
    SaveListingToIndex
  ]
end
