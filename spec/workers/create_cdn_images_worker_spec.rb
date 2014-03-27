require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
require 'webmock/rspec'
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
    worker = CreateCdnImagesWorker.new
    worker.perform(domain: @site.domain)
    WebMock.should have_requested(:get, "www.retailer.com/images/1.png")
    expect(CDN.has_image?(image_source)).to be_true
  end
end
