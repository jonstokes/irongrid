class ValidateListing
  include Interactor

  def perform
    case type
    when "AuctionListing"
      context.fail!(status: :auction_ended) if auction_ended?
    when "ClassifiedListing"
      context.fail!(status: :classified_sold) if classified_sold?
    end
    context.fail!(status: :invalid) if success? && !is_valid?
    context[:listing] = {} unless success?
  end

  def is_valid?
    !!(eval validation_string)
  end

  def classified_sold?
    !!raw_listing['item_sold']
  end

  def auction_ended?
    auction_ends = ListingFormat.time(time: raw_listing['auction_ends'], site: site)
    auction_ends.nil? || (auction_ends < Time.now)
  end

  def validation_string
    validation_type = type.split("Listing").first.downcase
    raw_listing['validation'][validation_type].gsub("raw", "raw_listing")
  end
end
