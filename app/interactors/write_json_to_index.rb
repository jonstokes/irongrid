class WriteJsonToIndex
  include Interactor::Organizer

  # Expect context to have site, page, listing_json

  organize [
    SetUrl,
    FindOrCreateListing,
    MergeJsonIntoListing,
    #SetProductDetails,
    RunLoadableScripts,
    SetListingDigest,
    SetListingLocation,
    UpdateListingImage,
    SaveListingToIndex
  ]
end


