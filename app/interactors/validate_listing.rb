class ValidateListing
  include Interactor

  def perform
    context.fail!(status: :invalid) unless is_valid?
    context.fail!(status: :classified_sold) if classified_sold?
    context.fail!(status: :auction_ended) if auction_ended?
  end

  def is_valid?
    !!(eval validation_string)
  end

  def classified_sold?
    !!raw_listing['item_sold']
  end

  def auction_ended?
    auction_ends = ListingFormat.time(time: raw_listing['auction_ends'], site: site)
    raw_listing['auction_ends'].nil? || (auction_ends < Time.now)
  end

  def validation_string
    validation_type = type.split("Listing").first.downcase
    adapter.validation[validation_type].gsub("raw", "raw_listing")
  end
end
