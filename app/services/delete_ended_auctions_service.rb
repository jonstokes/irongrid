class DeleteEndedAuctionsService < CoreService
  include ConnectionWrapper

  def start_jobs
    CoreService.mutex.synchronize {
      return if DeleteListingsWorker.queued_jobs.any?
      begin
        db do
          Listing.ended_auctions.find_in_batches do |batch|
            DeleteListingsWorker.perform_async(batch.map(&:id))
            record_incr(:jobs_started) unless Rails.env.test?
          end
        end
      end
    }
  end
end
