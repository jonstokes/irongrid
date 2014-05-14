require 'spec_helper'
require 'mocktra'

describe DecoratePage do
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

    it "takes in a Nokogiri doc and produces a DocReader object to wrap it" do
      url = "http://www.retailer.com/1.html"
      page = @http.fetch_page(url)
      result = DecoratePage.perform(page: page)

      expect(result.url).to eq(url)
      expect(result.doc).to be_a(DocReader)
      expect(result.doc.url).to eq(url)
    end
  end
end
