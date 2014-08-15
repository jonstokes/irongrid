require 'spec_helper'
require 'mocktra'

describe Stretched::RunSession do

  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    Stretched::RateLimit.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/rate_limits.yml")
    Stretched::SessionDefinition.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/session_definitions.yml")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/listing.json")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/product_link.json")
    Stretched::ObjectAdapter.create_from_file("spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
    Stretched::Script.create_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
    Stretched::SessionQueue.find_or_create("www.retailer.com")
    @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
  end

  describe "#perform" do
    it "should translate a page into JSON using a JSON adapter" do
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

      expect(result.json_objects).not_to be_empty

      listing = result.json_objects.first
      expect(listing['title']).to include("Ruger 3470 SR40 15+1 40S&")
      expect(listing['keywords']).to include("Ruger, 3470")
      expect(listing['location']).to eq("1105 Industry Road Lexington, KY 40505")
      expect(listing['image']).to eq("http://www.budsgunshop.com/catalog/images/69980_1.jpg")
      expect(listing['product_caliber']).to eq("Caliber   410/45 Long Colt")
      expect(listing['sale_price_in_cents']).to be_nil
    end

    it "should translate a page into JSON using a script" do
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
        adapter_name: "www.budsgunshop.com/product_page_scripts_only"
      )

      expect(result.json_objects).not_to be_empty

      listing = result.json_objects.first
      expect(listing['title']).to include("Ruger 3470 SR40 15+1 40S&")
      expect(listing['type']).to eq("RetailListing")
      expect(listing['image']).to eq("http://www.budsgunshop.com/catalog/images/69980_1.jpg")
      expect(listing['product_caliber']).to eq("410/45 Long Colt")
      expect(listing['location']).to be_nil
    end

    it "should translate a page into JSON using JSON and scripts combined" do
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
        adapter_name: "www.budsgunshop.com/product_page"
      )

      expect(result.json_objects).not_to be_empty

      listing = result.json_objects.first
      expect(listing['title']).to include("Ruger 3470 SR40 15+1 40S&")
      expect(listing['type']).to eq("RetailListing")
      expect(listing['location']).to eq("1105 Industry Road Lexington, KY 40505")
      expect(listing['image']).to eq("http://www.budsgunshop.com/catalog/images/69980_1.jpg")
      expect(listing['product_caliber']).to eq("410/45 Long Colt")
      expect(listing['sale_price_in_cents']).to eq(41100)
    end

    it "errors if the JSON adapter has an invalid attribute that doesn't match the schema" do
      Mocktra(@domain) do
        get '/products/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/product1.html") do |file|
            file.read
          end
        end
      end

      page = Stretched::PageUtils::Test.get_page(@product_url)

      expect {
        Stretched::ExtractJsonFromPage.perform(
          page: page,
          adapter_name: "www.budsgunshop.com/product_page_invalid_json_attribute"
        )
      }.to raise_error(RuntimeError, "Undefined property listing_type in schema Listing")
    end

    it "errors if the script has an invalid attribute that doesn't match the schema" do
      Mocktra(@domain) do
        get '/products/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/product1.html") do |file|
            file.read
          end
        end
      end

      Stretched::Script.create_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/invalid_script.rb")
      page = Stretched::PageUtils::Test.get_page(@product_url)

      expect {
        Stretched::ExtractJsonFromPage.perform(
          page: page,
          adapter_name: "www.budsgunshop.com/product_page_invalid_script_attribute"
        )
      }.to raise_error(RuntimeError, "Undefined property listing_type in schema Listing")
    end

  end

end
