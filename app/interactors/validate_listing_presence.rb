class ValidateListingPresence
  include Interactor

  def call
    context.fail!(status: :not_found) if page_not_found? || listing_json_not_found?
  end

  def listing_json_not_found?
    context.listing_json.nil? || context.listing_json.not_found
  end

  def page_not_found?
    !page.fetched? || page.error || !page.body? || page.code.nil? || (page.code.to_i == 404)
  end

  def page
    context.page
  end
end
