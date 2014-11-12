require 'spec_helper'
require 'mocktra'

describe UpdateListingImagesWorker do
  before :each do
    @site = create_site "www.retailer.com"
    Mocktra(@site.domain) do
      get '/images/1.png' do
        send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
      end
    end
  end

  it "updates listings that have no images when their images are on the CDN without stepping on updated_at timestamp" do
    listing = create(:listing, :no_image)
    CDN::Image.create(source: listing.image_source, http: Sunbro::HTTP.new)
    sleep 1
    UpdateListingImagesWorker.new.perform([listing.id])
    same_listing = IronBase::Listing.first
    expect(same_listing.image.cdn).to eq(CDN::Image.new(source: listing.image_source).cdn_url)
    expect(same_listing.updated_at).to eq(listing.updated_at)
    expect(same_listing.image.download_attempted).to be_true
  end

  it "marks the listing as image_download_attempted if the listing has no image_source" do
    # This takes the image out of the Listing.no_image scope, so that the platform doesn't keep trying to
    # update it with this worker
    listing = FactoryGirl.create(:listing, :no_image)
    listing.image.source = nil
    listing.save
    UpdateListingImagesWorker.new.perform([listing.id])
    same_listing = IronBase::Listing.first
    expect(same_listing.image.source).to be_nil
    expect(same_listing.image.cdn).to eq(CDN::DEFAULT_IMAGE_URL)
    expect(same_listing.image.download_attempted).to be_true
  end

  it "does nothing if the listing has been deleted" do
    pending "Example"
  end
end
