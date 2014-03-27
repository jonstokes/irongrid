class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper
  include Retryable
  include Trackable

  LOG_RECORD_SCHEMA = {
    listings_updated: Integer,
    transition:       String
  }

  def perform
    track
    Listing.where("item_data->>'image' = ? AND updated_at > ?", CDN::DEFAULT_IMAGE_URL, 1.days.ago).limit(500).each do |listing|
      next unless CDN.has_image?(listing.image_source)
      listing.image = CDN.url_for_image(listing.image_source)
      db { listing.update_record_without_timestamping }
      record_incr(:listings_updated)
    end
    transition
    stop_tracking
  end

  def transition
    if Listing.find("item_data->>'image' = ? AND updated_at > ?", CDN::DEFAULT_IMAGE_URL, 1.days.ago)
      UpdateListingImagesWorker.perform_async
      record_set(:transition, "UpdateListingImagesWorker")
    end
  end
end
