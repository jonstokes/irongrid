class ValidateListing
  include Interactor

  def call
    # TODO: put all the timezone translation logic into IronBase::Listing
    # TODO: Also add timezone to all auction listings in stretched
    context.fail!(status: :not_found) if auction_ended? || page_not_found? || listing_json_not_found?
    context.fail!(status: :invalid) unless context.listing_json.is_valid?
  end

  def auction_ended?
    context.listing.auction? && context.listing.auction_ended?
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