class DeleteListingsWorker < CoreWorker
  include Trackable

  sidekiq_options queue: :db_slow_high, retry: true

  LOG_RECORD_SCHEMA = {
    listings_deleted: Integer
  }

  # TODO: Refactor to use bulk API
  def perform(listing_ids)
    track
    listing_ids.each do |id|
      listing = IronBase::Listing.find(id)
      next unless listing
      record_incr(:listings_deleted) if retryable(sleep: 1) { listing.destroy }
    end
    stop_tracking
  end

  def self.queued_jobs
    jobs_for_class("DeleteListingsWorker")
  end
end
