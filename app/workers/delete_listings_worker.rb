class DeleteListingsWorker < CoreWorker
  include Trackable

  sidekiq_options queue: :db_slow_high, retry: true

  LOG_RECORD_SCHEMA = {
    listings_deleted: Integer
  }

  # TODO: Refactor to use bulk API
  def perform(listing_ids)
    track
    batch1 = listing_ids[0..249].try(:compact)
    batch2 = listing_ids[250..500].try(:compact)

    if batch1.try(:any?)
      IronBase::Listing.bulk_delete(batch1)
      record_set(:listings_deleted, batch1.size)
    end
    if batch2.try(:any?)
      IronBase::Listing.bulk_delete(batch2)
      record_set(:listings_deleted, batch2.size)
    end

    stop_tracking
  rescue Elasticsearch::Transport::Transport::Errors::InternalServerError
    stop_tracking
  end

  def self.queued_jobs
    jobs_for_class("DeleteListingsWorker")
  end
end
