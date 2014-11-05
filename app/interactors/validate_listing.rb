class ValidateListing
  include Interactor

  def call
    context.fail!(status: :not_found) if (context.listing.type == 'AuctionListing') && auction_ended?
    context.fail!(status: :invalid) if context.success? && !is_valid?
  end

  def is_valid?
    context.listing_json.valid?
  end

  def auction_ended?
    context.listing.auction_ends.nil? || (context.listing.auction_ends < Time.now.utc)
  end

end
