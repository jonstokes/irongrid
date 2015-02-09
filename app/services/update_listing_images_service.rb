class UpdateListingImagesService < BaseService
  track_with_schema jobs_started: Integer
  poll_interval 3600
  worker_class UpdateListingImagesWorker

  def each_job
    IronBase::Listing.with_each_no_image do |batch|
      yield(batch.map(&:id))
    end
  end
end
