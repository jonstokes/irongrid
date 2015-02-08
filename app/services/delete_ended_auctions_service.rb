class DeleteEndedAuctionsService < Bellbro::Service

  poll_interval 10800
  track_with_schema jobs_started: Integer

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
