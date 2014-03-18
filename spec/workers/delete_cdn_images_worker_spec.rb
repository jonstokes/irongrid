require 'spec_helper'

describe DeleteCdnImagesWorker do
  it "after all listings are updated, it deletes a batch of stale, orphaned images from S3" do
    pending  "Example"
    # Check S3Object.updated_at to make sure the image is over a day old
    # Needs to Listing.find_by_image
    #
    # It only delete images whose last_modified was over a week ago

  it "does not delete an image from the CDN if the image is still in use" do
    pending "Example"
  end

  it "does not delete an image if it was last modified less than a week ago" do
    pending "Example"
  end
end
