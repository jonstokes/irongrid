require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'

describe Stretched::RunSessionsWorker do
  before :each do
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all

    Stretched::Registration.with_redis { |c| c.flushdb }
    @user = "test@ironsights.com"
    register_stretched_globals(@user)
    register_site @user, "www.budsgunshop.com"

    @worker = Stretched::RunSessionsWorker.new
    @domain = "www.budsgunshop.com"
    @session_q = Stretched::SessionQueue.find_or_create(@user, @domain)
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

      object_q = Stretched::ObjectQueue.find_or_create(@user, "www.budsgunshop.com/product_links")
      expect(object_q.size).to be_zero

      @worker.perform(user: @user, queue: @domain)

      expect(object_q.size).to eq(162)
      while result = object_q.pop
        if !!result.page.url[/catalog\/1/]
          expect(result.object.product_link).not_to be_nil
          expect(result.object.product_link).to include("http")
        end
      end
    end


  end
end
