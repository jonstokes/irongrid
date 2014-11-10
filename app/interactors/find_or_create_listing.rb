class FindOrCreateListing
  include Interactor

  def call
    context.listing = IronBase::Listing.find(listing_id) || IronBase::Listing.new(id: listing_id)
  end

  rollback do
    if not_found?
      [context.page.redirect_from, context.page.url].each do |url|
        Listing.find_by_url(url).each do |listing|
          listing.destroy
        end
      end
    elsif context.listing.persisted?
      if listing_is_duplicate? || page_redirected?
        context.listing.destroy
      else
        context.listing.deactivate!
      end
    end
  end

  def listing_id
    id_tagged_url || purchase_url
  end

  def id_tagged_url
    return unless context.listing_json.id
    "#{purchase_url}!#{listing_json.id}"
  end

  def purchase_url
    context.url.purchase
  end

  def page_redirected?
    [301, 302].include?(context.page.code)
  end

  def not_found?
    context.status == :not_found
  end

  def listing_is_duplicate?
    context.status == :duplicate
  end
end