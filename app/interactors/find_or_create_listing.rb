class FindOrCreateListing
  include Interactor

  def call
    listing_purchase_url = listing_json.url || page_url
    listing_id = tagged_url || listing_purchase_url
    context.listing = IronBase::Listing.find(listing_id) || IronBase::Listing.new
    context.listing.url = {
        page: page_url,
        purchase: listing_purchase_url
    }
  end

  def tagged_url
    "#{listing_purchase_url}!#{listing_json.id}" if listing_json.id
  end

  def page_url
    if context.page.code == 302    # Temporary redirect, so
      context.page.redirect_from   # preserve original url
    else
      context.page.url
    end
  end

  def listing_json
    context.listing_json
  end
end