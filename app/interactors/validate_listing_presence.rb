class ValidateListingPresence
  include Interactor

  def perform
    context[:listing] = nil
    context.fail!(status: :not_found) if !!raw_listing['not_found']
  end
end
