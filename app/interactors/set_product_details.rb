class SetProductDetails
  include Interactor::Organizer

  organize [
    ProductDetails::ScrubMetadataSourceAttributes,
    ProductDetails::ExtractMetadataFromRawListing,
    ProductDetails::ExtractMetadataFromSourceAttributes,
    ProductDetails::SoftCategorize
  ]

end
