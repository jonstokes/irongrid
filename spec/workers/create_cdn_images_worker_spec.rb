require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
require 'webmock/rspec'
Sidekiq::Testing.fake!

describe CreateCdnImagesWorker do
  before :each do
    @site = create_site "www.retailer.com"
    Sidekiq::Worker.clear_all
    CDN.clear!
    IronCore::ImageQueue.new(domain: @site.domain).clear
    Mocktra(@site.domain) do
      get '/images/1.png' do
        send_file "#{Rails.root}/spec/fixtures/images/test-image.png"
      end
    end
  end

  describe "#perform" do
    it "downloads an image that's not already on the CDN" do
      image_source = "http://www.retailer.com/images/1.png"
      iq = IronCore::ImageQueue.new(domain: @site.domain)
      iq.push image_source
      worker = CreateCdnImagesWorker.new
      worker.perform(domain: @site.domain)
      WebMock.should have_requested(:get, "www.retailer.com/images/1.png")
      expect(CDN.has_image?(image_source)).to eq(true)
    end
  end

  describe "#transition" do
    it "transitions to self if the image queue is not empty" do
      iq = IronCore::ImageQueue.new(domain: @site.domain)
      5.times { |i| iq.push "http://#{@site.domain}/images/#{i}.png" }
      worker = CreateCdnImagesWorker.new
      worker.perform(domain: @site.domain, timeout: 1)
      expect(CreateCdnImagesWorker.jobs.count).to eq(1)
    end

    it "does not transition to self if the image queue is empty" do
      iq = IronCore::ImageQueue.new(domain: @site.domain)
      iq.push "http://#{@site.domain}/images/1.png"
      worker = CreateCdnImagesWorker.new
      worker.perform(domain: @site.domain, timeout: 1)
      expect(iq.size).to eq(0)
      expect(CreateCdnImagesWorker.jobs.count).to eq(0)
    end
  end
end
