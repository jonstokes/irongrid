class UpdateListingImagesWorker < CoreWorker
  include ConnectionWrapper
  include Retryable

  def perform
    Listing.where("item_data->>'image' = ? AND updated_at > ?", CDN::DEFAULT_IMAGE_URL, 1.days.ago).each do |listing|
      next unless CDN.has_image?(listing.image_source)
      listing.image = CDN.url_for_image(listing.image_source)
      db { listing.update_record_without_timestamping }
    end
  end
end
