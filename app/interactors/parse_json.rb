class ParseJson
  include Interactor::Organizer

  # Expect context to have site, page, url, listing_json

  organize [
    ValidateListingPresence,
    CopyAttributes,
    DeriveAttributes,
    ValidateListing,
    SetProductDetails,
    SetPricePerRound,
    CalculateShipping,
    WriteListing,
  ]

  def is_valid?
    success?
  end

  def not_found?
    !success? && status == :not_found
  end
end


