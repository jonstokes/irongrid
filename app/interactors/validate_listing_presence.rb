class ValidateListingPresence
  include Interactor

  def perform
    context[:listing] = nil
    context[:listing_json] = context[:object]
    context[:url] = listing_json.try(:url)
    context.fail!(status: :not_found) if not_found?
  end

  def not_found?
    !page.fetched? || page.error || !page.body? || page.code.nil? || (page.code.to_i == 404) || listing_json.try(:not_found?)
  end
end
