require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe CreateCdnImagesWorker do
  before :each do
    @site = create_site_from_repo "www.retailer.com"
    CDN.clear!
    ImageQueue.new(domain: @site.domain).clear
    Mocktra(@site.domain) do
      get '/images/1.png' do
        send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
      end
    end
  end

  it "downloads an image that's not already on the CDN" do
    image_source = "http://www.retailer.com/images/1.png"
    iq = ImageQueue.new(domain: @site.domain)
    iq.push image_source
    CreateCdnImagesWorker.new.perform(domain: @site.domain)
    expect(CDN.has_image?(image_source)).to be_true
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
  it "pulls an image url from the IS for a domain" do
    pending "Example"
  end

  it "respects the site's rate limits" do
    pending "Example"
  end
end
