require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'

describe Stretched::RunSessionsWorker do
  before :each do
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all

    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals
    register_site "www.budsgunshop.com"

    @worker = Stretched::RunSessionsWorker.new
    @domain = "www.budsgunshop.com"
    @session_q = Stretched::SessionQueue.find_or_create(@domain)
    @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
    @session_q.add(@sessions)

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

      object_q = Stretched::ObjectQueue.find_or_create("www.budsgunshop.com/product_links")
      expect(object_q.size).to be_zero

      @worker.perform(queue: @domain)

      expect(object_q.size).to eq(162)
      object = object_q.pop.object
      expect(object['product_link']).to include("http")
    end


  end
end
