class UpdateListingImagesService < CoreService
  include ConnectionWrapper

  def each_job
    CoreService.mutex.synchronize {
      begin
        db do
          Listing.no_image.find_in_batches do |batch|
            yield(klass: "UpdateListingImagesWorker", arguments: batch.map(&:id))
          end
        end
      end
    }
  end
end
