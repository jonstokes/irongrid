require 'spec_helper'
require 'mocktra'

describe Stretched::ExtractJsonFromPage do

  before :each do
    @domain = "www.budsgunshop.com"
    @product_url = "http://#{@domain}/products/1"
  end

  describe "#perform" do
    it "should translate a page into JSON using a schema" do

      Mocktra(@domain) do
        get '/products/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/product1.html") do |file|
            file.read
          end
        end
      end

      page = Stretched::PageUtils::Test.get_page(@product_url)

      expect(page).not_to be_nil
      expect(page.doc).not_to be_nil

    end
  end

end
