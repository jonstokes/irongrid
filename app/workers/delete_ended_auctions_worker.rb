class DeleteEndedAuctionsWorker < CoreWorker

  sidekiq_options queue: :fast_db, retry: true

  LOG_RECORD_SCHEMA = {
    listings_deleted: Integer
  }

  def perform(listing_ids)
    track
    listing_ids.each do |id|
      listing = Listing.find(id) rescue nil
      record_incr(:listings_deleted) if listing.try(:destroy)
    end
    stop_tracking
  end

  def self.queued_jobs
    jobs_for_class("DeleteEndedAuctionsWorker")
  end
end
