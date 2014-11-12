class UpdateListingImagesService < CoreService
  include ConnectionWrapper

  def each_job
    CoreService.mutex.synchronize {
      begin
        IronBase::Listing.with_each_no_image do |batch|
          yield(klass: 'UpdateListingImagesWorker', arguments: batch.map(&:id))
        end
      end
    }
  end
end
