class UpdateListingImagesService < CoreService
  include ConnectionWrapper

  def start_jobs
    CoreService.mutex.synchronize {
      begin
        db do
          Listing.no_image.find_in_batches do |batch|
            UpdateListingImagesWorker.perform_async(batch.map(&:id))
            record_incr(:jobs_started) unless Rails.env.test?
          end
        end
      end
    }
  end
end
