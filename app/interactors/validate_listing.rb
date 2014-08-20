class ValidateListing
  include Interactor

  def perform
    context.fail!(status: :auction_ended) if (listing_json.type == "AuctionListing") && auction_ended?
    context.fail!(status: :invalid) if success? && !is_valid?
    context[:listing] = {} unless success?
  end

  def is_valid?
    listing_json.valid?
  end

  def auction_ended?
    auction_ends = ListingFormat.time(time: listing_json['auction_ends'], site: site)
    auction_ends.nil? || (auction_ends < Time.now)
  end

end
