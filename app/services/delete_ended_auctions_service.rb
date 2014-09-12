class DeleteEndedAuctionsService < CoreService
  include ConnectionWrapper

  SLEEP_INTERVAL = 10800

  def each_job
    CoreService.mutex.synchronize {
      begin
        db do
          Listing.ended_auctions.find_in_batches do |batch|
            yield(klass: "DeleteListingsWorker", arguments: batch.map(&:id))
          end
        end
      end
    }
  end
end
