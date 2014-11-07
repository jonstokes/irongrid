class FindOrCreateListing
  include Interactor

  def call
    listing_purchase_url = listing_json.url || current_url
    listing_id = if listing_json.id
                   "#{listing_purchase_url}!#{listing_json.id}"
                 else
                   listing_purchase_url
                 end
    context.listing = IronBase::Listing.find(listing_id) || IronBase::Listing.new
    context.listing.url.page = current_url
    context.listing.url.purchase = listing_purchase_url
  end

  def current_url
    if page.code == 302    # Temporary redirect, so
      page.redirect_from   # preserve original url
    else
      page.url
    end
  end

  def page
    context.page
  end

  def listing_json
    context.listing_json
  end
end