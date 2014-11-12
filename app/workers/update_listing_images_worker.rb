class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  sidekiq_options queue: :db_slow_low, retry: true

  LOG_RECORD_SCHEMA = {
    listings_updated: Integer,
  }

  def perform(listing_ids)
    track
    listing_ids.each do |id|
      next unless listing = IronBase::Listing.find(id)
      update_listing(listing) && next unless listing.image.source.try(:present?)

      image = CDN::Image.new(source: listing.image.source)
      if image.exists?
        listing.image.cdn = image.cdn_url
        update_listing(listing)
      end
    end
    stop_tracking
  end

  def update_listing(listing)
    listing.image.download_attempted = true
    listing.update_record_without_timestamping
    record_incr(:listings_updated)
  end
end
