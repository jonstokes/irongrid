class UpdateListingImagesService < Bellbro::Service

  def each_job
    Bellbro::Service.mutex.synchronize {
      begin
        IronBase::Listing.with_each_no_image do |batch|
          yield(klass: 'UpdateListingImagesWorker', arguments: batch.map(&:id))
        end
      end
    }
  end
end
