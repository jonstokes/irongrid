class DeleteEndedAuctionsService < Bellbro::Service

  SLEEP_INTERVAL = 10800

  def each_job
    Bellbro::Service.mutex.synchronize {
      begin
        IronBase::Listing.with_each_ended_auction do |batch|
          yield(klass: 'DeleteListingsWorker', arguments: batch.map(&:id))
        end
      end
    }
  end
end
