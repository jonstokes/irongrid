class ValidateListingPresence
  include Interactor

  def perform
    context[:listing] = nil
    context.fail!(status: :not_found) if listing_json.not_found?
  end
end
