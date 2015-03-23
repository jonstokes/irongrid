class DeleteListingsWorker < BaseWorker

  sidekiq_options queue: :db_slow_high, retry: true

  track_with_schema(
    listings_deleted: Integer
  )

  before :should_run?, :track
  after :stop_tracking

  def call
    batch1 = listing_ids[0..249].try(:compact)
    batch2 = listing_ids[250..500].try(:compact)

    if batch1.try(:any?)
      Retryable.retryable(sleep: 1) { IronBase::Listing.bulk_delete(batch1) }
      record_set(:listings_deleted, batch1.size)
    end
    
    if batch2.try(:any?)
      Retryable.retryable(sleep: 1) { IronBase::Listing.bulk_delete(batch2) }
      record_set(:listings_deleted, batch2.size)
    end
  rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
    error "A listing batch raised #{e.message}"
  end

  def should_run?
    listing_ids.try(:any?) || abort!
  end

  def listing_ids; @context; end

  def self.queued_jobs
    jobs_for_class("DeleteListingsWorker")
  end
end
