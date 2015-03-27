class DeleteEndedAuctionsService < BaseService

  poll_interval 10800
  track_with_schema jobs_started: Integer
  worker_class DeleteListingsWorker

  def each_job
    Retryable.retryable(on: NoMethodError) do
      IronBase::Listing.with_each_ended_auction do |batch|
        yield(batch.map(&:id))
      end
    end
  end
end
