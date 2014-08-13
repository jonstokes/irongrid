require 'spec_helper'
require 'mocktra'

describe Stretched::ExtractJsonFromPage do

  before :each do
    @domain = "www.budsgunshop.com"
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

      #stuff

    end
  end

end
