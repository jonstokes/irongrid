require 'spec_helper'
require 'mocktra'

describe UpdateListingImagesWorker do
  before :all do
    @site = create_site_from_repo "www.retailer.com"
    Mocktra(@site.domain) do
      get '/images/1.png' do
        send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
      end
    end
  end

  it "updates listings that have nil images when their images are on the CDN without stepping on updated_at timestamp" do
    listing = FactoryGirl.create(:retail_listing, :no_image)
    CDN.upload_image(listing.image_source)
    sleep 1
    UpdateListingImagesWorker.new.perform
    same_listing = Listing.first
    expect(same_listing.image).to eq(CDN.url_for_image(listing.image_source))
    expect(same_listing.updated_at).to eq(listing.updated_at)
  end
end
