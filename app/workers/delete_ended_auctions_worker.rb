class DeleteEndedAuctionsWorker < CoreWorker
  include Trackable

  sidekiq_options queue: :fast_db

  LOG_RECORD_SCHEMA = {
    listings_deleted: Integer
  }

  def perform(listing_ids)
    track
    listing_ids.each do |id|
      record_incr(:listings_deleted) if Listing.find(id).try(:destroy)
    end
    stop_tracking
  end
end
