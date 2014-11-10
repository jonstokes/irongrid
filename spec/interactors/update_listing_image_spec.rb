require 'spec_helper'
require 'mocktra'
require 'webmock/rspec'


describe UpdateListingImage do
  before :each do
    @site = create_site "www.retailer.com"
    @image_source = "http://www.retailer.com/images/1.png"
    CDN.clear!
    @iq = ImageQueue.new(domain: @site.domain)
    @iq.clear
    @listing = IronBase::Listing.new(
        attributes_for(:listing).merge(image: { source: @image_source })
    )
  end

  describe '#call' do
    it 'adds an image to the site site image queue if the listing image is not on the CDN' do
      listing = UpdateListingImage.call(
          site: @site,
          listing: @listing
      ).listing
      expect(@iq.size).to eq(1)
      expect(listing.image.cdn).to eq(CDN::DEFAULT_IMAGE_URL)
    end

    it 'sets the listing cdn image if that image is present on the cdn' do
      Mocktra(@site.domain) do
        get '/images/1.png' do
          send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
        end
      end

      http = Sunbro::HTTP.new
      CDN::Image.create(source: @image_source, http: http)

      listing = UpdateListingImage.call(
          site: @site,
          listing: @listing
      ).listing
      expect(@iq.size).to eq(0)

      expect(listing.image.cdn).to eq(CDN.url_for_image(@image_source))

    end
  end
end