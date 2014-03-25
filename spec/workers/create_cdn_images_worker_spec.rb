require 'spec_helper'

describe CreateCdnImagesWorker do
  it "pulls an image url from the IS for a domain" do
    pending "Example"
  end

  it "respects the site's rate limits" do
    pending "Example"
  end

  it "downloads an image that's not already on the CDN" do
    pending "Example"
  end

  it "does not download an image that's already on the CDN" do
    pending "Example"
  end

  it "resizes an image that's over 200x200 before uploading it to the CDN" do
    pending "Example"
  end

  it "does not try to download a busted image more than three times over the life of a listing" do
    pending "Example"
    # Check listing.image_download_count
    # If listing.image_download_count > 3 don't bother
    # Else try to pull the listing
    #   if the listing is there, then
    #      d/l and resize and add to CDN and clear image_download_count
    #   else increment the image_download_count
    #
  end
end
