class ValidateListing
  include Interactor

  def perform
    context.fail!(status: :auction_ended) if (type == "AuctionListing") && auction_ended?
    context.fail!(status: :invalid) if success? && !is_valid?
    context[:listing] = {} unless success?
  end

  def is_valid?
    listing.valid?
  end

  def auction_ended?
    auction_ends = ListingFormat.time(time: listing_json['auction_ends'], site: site)
    auction_ends.nil? || (auction_ends < Time.now)
  end

end
