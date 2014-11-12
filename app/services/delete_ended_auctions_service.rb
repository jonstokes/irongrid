class DeleteEndedAuctionsService < CoreService
  include ConnectionWrapper

  SLEEP_INTERVAL = 10800

  def each_job
    CoreService.mutex.synchronize {
      begin
        db do
          Listing.with_each_ended_auction do |batch|
            yield(klass: "DeleteListingsWorker", arguments: batch.map(&:id))
          end
        end
      end
    }
  end
end
