class ValidateListingPresence
  include Interactor

  def perform
    context[:listing] = nil
    context[:listing_json] = object
    context[:url] = listing_json.url
    context.fail!(status: :not_found) if not_found?(page) || listing_json.not_found?
  end

  def not_found?(page)
    !page.fetched? || page.error || !page.body? || page.code.nil? || (page.code.to_i == 404)
  end
end
