require 'spec_helper'
require 'mocktra'

describe Stretched::ExtractJsonFromPage do

  before :each do
    @domain = "www.budsgunshop.com"
    @product_url = "http://#{@domain}/products/1"

    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/listing.json")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/product_link.json")
    Stretched::ObjectAdapter.create_from_file("spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
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

      result = Stretched::ExtractJsonFromPage.perform(
        page: page,
        adapter_name: "www.budsgunshop.com/product_page_no_script"
      )

      expect(result.json_objects).not_to be_empty?

      listing = result.json_objects.first
      expect(listing['title']).to eq("1911")
    end
  end

end
