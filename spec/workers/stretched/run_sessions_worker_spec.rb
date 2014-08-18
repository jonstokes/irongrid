require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'

describe Stretched::RunSessionsWorker do
  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all

    @worker = Stretched::RunSessionsWorker.new
    @domain = "www.budsgunshop.com"
    @session_q = Stretched::SessionQueue.find_or_create(@domain)
    @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
    @session_q.add(@sessions)

    Stretched::RateLimit.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/rate_limits.yml")
    Stretched::SessionDefinition.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/session_definitions.yml")
    Stretched::Schema.register_from_file("spec/fixtures/stretched/registrations/schemas/listing.json")
    Stretched::Schema.register_from_file("spec/fixtures/stretched/registrations/schemas/product_link.json")
    Stretched::Script.register_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
    Stretched::ObjectAdapter.register_from_file("spec/fixtures/stretched/registrations/object_adapters/globals.yml")
    Stretched::ObjectAdapter.register_from_file("spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
    Stretched::SessionQueue.find_or_create("www.retailer.com")
  end

  describe "#perform" do
    it "empties the session_queue, extracts JSON objects from the pages, and adds the objects to the object_queue" do
      Mocktra(@domain) do
        get '/catalog/1' do
          File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/1911-listing-page.html") do |file|
            file.read
          end
        end
      end

      object_q = Stretched::ObjectQueue.find_or_create("ProductLink")
      expect(object_q.size).to be_zero

      @worker.perform(queue: @domain)

      expect(object_q.size).to eq(50)
    end


  end
end
