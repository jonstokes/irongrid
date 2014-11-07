class ValidateListingPresence
  include Interactor

   def call
    context.fail!(status: :not_found) if not_found?
  end

  def not_found?
    !page.fetched? || page.error || !page.body? ||
        page.code.nil? || (page.code.to_i == 404) || context.listing_json.try(:not_found)
  end

  def page
    context.page
  end
end
