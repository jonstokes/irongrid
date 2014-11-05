class ValidateListingPresence
  include Interactor

  def call
    context.listing = nil
    context.listing_json = context.object
    context.url = context.listing_json.try(:url)
    context.fail!(status: :not_found) if not_found?
  end

  def not_found?
    !page.fetched? || page.error || !page.body? || page.code.nil? || (page.code.to_i == 404) || listing_json.try(:not_found)
  end

  def page
    context.page
  end

  def listing_json
    context.listing_json
  end
end
