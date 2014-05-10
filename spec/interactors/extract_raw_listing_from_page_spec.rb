require 'spec_helper'
require 'mocktra'

describe ExtractRawListingFromPage do
  before :each do
    @http = PageUtils::HTTP.new
  end

  describe "#perform" do
    Mocktra("www.retailer.com") do
      get '/1.html' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/1.html") do |file|
          file.read
        end
      end
    end
  end
end

