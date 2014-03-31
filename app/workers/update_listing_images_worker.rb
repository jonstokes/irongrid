class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper

  LOG_RECORD_SCHEMA = {
    listings_updated: Integer,
    transition:       String
  }

  def perform
    track
    listings = db { Listing.no_image.limit(500) }
    listings.each do |listing|
      next unless CDN.has_image?(listing.image_source)
      listing.image = CDN.url_for_image(listing.image_source)
      listing.item_data_will_change!
      db { listing.update_record_without_timestamping }
      record_incr(:listings_updated)
    end
    transition
    stop_tracking
  end

  def transition
    if db { Listing.no_image.limit(1).any? }
      UpdateListingImagesWorker.perform_async
      record_set(:transition, "UpdateListingImagesWorker")
    end
  end
end
