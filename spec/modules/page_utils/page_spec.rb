require 'spec_helper'
require 'mocktra'

describe Sunbro::Page do

  before :each do
    @http = Sunbro::HTTP.new
  end

  describe "#initialize", no_es: true do
    it "it scrubs invalid UTF-8 from @body by converting to UTF-16, then back again" do
      # See http://stackoverflow.com/a/8873922/1169868
      pending "Example"
    end
  end

  describe "#doc", no_es: true do
    it "uses the correct Nokogiri parser to parse html or xml, or lets Nokogiri guess" do
      pending "Example"
    end
  end

  describe "#should_parse_as?", no_es: true do
    Mocktra("www.retailer.com") do
      get '/1.html' do
        File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/1.html") do |file|
          file.read
        end
      end
    end

    it "returns true if Nokogiri should try to parse the page with the supplied format, false otherwise" do
      url = "http://www.retailer.com/1.html"

      page = @http.fetch_page(url)
      expect(page.send(:should_parse_as?, :xml)).to be_false
      expect(page.send(:should_parse_as?, :html)).to be_true

      page = @http.fetch_page(url, force_format: :html)
      expect(page.send(:should_parse_as?, :xml)).to be_false
      expect(page.send(:should_parse_as?, :html)).to be_true

      page = @http.fetch_page(url, force_format: :xml)
      expect(page.send(:should_parse_as?, :xml)).to be_true
      expect(page.send(:should_parse_as?, :html)).to be_false
    end
  end
end
