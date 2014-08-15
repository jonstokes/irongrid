require 'spec_helper'
require 'mocktra'

describe Stretched::RunSession do

  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    Stretched::RateLimit.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/rate_limits.yml")
    Stretched::SessionDefinition.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/session_definitions.yml")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/listing.json")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/product_link.json")
    Stretched::Script.create_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
    Stretched::ObjectAdapter.create_from_file("spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
    Stretched::SessionQueue.find_or_create("www.retailer.com")
    @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
    @domain = "www.budsgunshop.com"
  end

  describe "#perform" do
    it "runs a session and extracts JSON objects from the pages" do
      Mocktra(@domain) do
        get '/catalog/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/1911-listing-page.html") do |file|
            file.read
          end
        end
      end

      object_q = Stretched::ObjectQueue.find_or_create "ProductLink"
      expect(object_q.size).to be_zero

      ssn = Stretched::Session.new(@sessions.last)
      result = Stretched::RunSession.perform(stretched_session: ssn)
      expect(object_q.size).to eq(50)
      expect(result.pages_scraped).to eq(2)
    end

    it "runs a session with link expansions and extracts JSON objects from the pages" do
      Mocktra(@domain) do
        get '/catalog/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/1911-listing-page.html") do |file|
            file.read
          end
        end
      end

      object_q = Stretched::ObjectQueue.find_or_create "ProductLink"
      expect(object_q.size).to be_zero

      ssn = Stretched::Session.new(@sessions.first)
      result = Stretched::RunSession.perform(stretched_session: ssn)
      expect(object_q.size).to eq(50)
      expect(result.pages_scraped).to eq(8)
    end

  end

end
