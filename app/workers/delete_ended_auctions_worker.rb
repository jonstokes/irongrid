class DeleteEndedAuctionsWorker < CoreWorker

  sidekiq_options queue: :fast_db, retry: true

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

  def self.queued_jobs
    jobs_for_class("DeleteEndedAuctionsWorker")
  end
end
