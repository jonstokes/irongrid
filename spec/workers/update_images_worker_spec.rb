require 'spec_helper'

describe UpdateImagesWorker do
  it "deletes stale, orphaned images from S3" do
    pending  "Example"
    # Check S3Object.updated_at to make sure the image is over a day old
    # Needs to Listing.find_by_image
  end

  it "does not delete an image from the CDN if the image is still in use" do
    pending "Example"
  end

  it "updates listings that have nil images when their images are on the CDN" do
    pending "Example"
    # Listing.where("item_data->>'image' = ?, updated_at < ?", nil, 2.days.ago).each do |listing|
    #   listing.image = CDN.url_for_image(listing.image) [this returns nil if the image isn't on the CDN]
    # end
  end
end
