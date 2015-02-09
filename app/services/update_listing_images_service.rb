class UpdateListingImagesService < Bellbro::Service
  track_with_schema jobs_started: Integer
  poll_interval 3600

  def each_job
    IronBase::Listing.with_each_no_image do |batch|
      yield(klass: 'UpdateListingImagesWorker', arguments: batch.map(&:id))
    end
  end
end
