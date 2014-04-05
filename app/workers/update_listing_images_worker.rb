class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  sidekiq_options queue: :fast_db, retry: true

  LOG_RECORD_SCHEMA = {
    listings_updated: Integer,
  }

  def perform(listing_ids)
    track
    listing_ids.each do |id|
      next unless listing = Listing.find(id)
      next unless listing.image_source && CDN.has_image?(listing.image_source)
      listing.image = CDN.url_for_image(listing.image_source)
      listing.image_download_attempted = true
      listing.item_data_will_change!
      db { listing.update_record_without_timestamping }
      record_incr(:listings_updated)
    end
    stop_tracking
  end
end
