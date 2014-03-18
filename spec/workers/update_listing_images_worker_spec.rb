require 'spec_helper'

describe UpdateListingImagesWorker do
  it "updates listings that have nil images when their images are on the CDN" do
    pending "Example"
    # Listing.where("item_data->>'image' = ?, updated_at < ?", nil, 2.days.ago).each do |listing|
    #   listing.image = CDN.url_for_image(listing.image) [this returns nil if the image isn't on the CDN]
    # end
  end
end
