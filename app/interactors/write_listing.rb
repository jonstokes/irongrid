class WriteListing
  include Interactor::Organizer

  organize [
    ListingWriter::SetDigest,
    ListingWriter::SaveListingToIndex,
  ]
end
