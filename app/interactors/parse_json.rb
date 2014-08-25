class ParseJson
  include Interactor::Organizer

  # Expect context to have site, page, url, listing_json

  organize [
    ValidateListingPresence,
    SetCommonAttributes, # includes setting auction_ends
    SetPriceAttributes,
    ValidateListing,
    ScrubMetadataSourceAttributes,
    ExtractMetadataFromRawListing,
    ExtractMetadataFromSourceAttributes,
    SoftCategorize,
    SetPricePerRound,
    SetDigest,
    GenerateListingHash
  ]

  def is_valid?
    success?
  end

  def not_found?
    !success? && status == :not_found
  end

  def classified_sold?
    !success? && status == :classified_sold
  end
end


