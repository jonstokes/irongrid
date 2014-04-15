class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  sidekiq_options queue: :slow_db, retry: true

  LOG_RECORD_SCHEMA = {
    listings_updated: Integer,
  }

  def perform(listing_ids)
    track
    listing_ids.each do |id|
      next unless listing = Listing.find(id) rescue nil
      update_listing(listing) && next unless listing.image_source.present?

      image = CDN::Image.new(source: listing.image_source)
      if image.exists?
        listing.image = image.cdn_url
        update_listing(listing)
      end
    end
    stop_tracking
  end

  def update_listing(listing)
    listing.image_download_attempted = true
    listing.item_data_will_change!
    db { listing.update_record_without_timestamping }
    record_incr(:listings_updated)
  end
end
