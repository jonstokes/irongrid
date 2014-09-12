class WriteListing
  include Interactor::Organizer

  organize [
    ListingWriter::SetDigest,
    ListingWriter::GenerateListingHash
  ]
end
