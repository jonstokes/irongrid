require 'spec_helper'
require 'mocktra'

describe Stretched::RunSession do
  describe "#perform" do

    before :each do
      Stretched::Registration.with_redis { |c| c.flushdb }
      @user = "test@ironsights.com"
      Stretched::Extension.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
      Stretched::Script.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
      Stretched::Script.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
    end

    describe "product pages" do
      before :each do
        Stretched::Registration.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
        Stretched::Script.register_from_file(@user, "spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
        Stretched::ObjectAdapter.register_from_file(@user, "spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
        @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
        @domain = "www.budsgunshop.com"
      end

      it "adds an empty JSON object for a 404 page" do
        Mocktra(@domain) do
          get '/products/1' do
            404
          end
        end

        object_q = Stretched::ObjectQueue.find_or_create @user, "www.budsgunshop.com/product_links"
        expect(object_q.size).to be_zero

        ssn = Stretched::Session.new(@user, @sessions.last.merge('key' => "abcd123"))
        result = Stretched::RunSession.perform(stretched_session: ssn)

        expect(object_q.size).to eq(2)
        object = object_q.pop
        expect(object[:page]['code']).to eq(404)
        expect(object[:session]['key']).to eq("abcd123")
      end

      it "runs a session and extracts JSON objects from catalog pages" do
        Mocktra(@domain) do
          get '/catalog/1' do
            File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/1911-listing-page.html") do |file|
              file.read
            end
          end
        end

        object_q = Stretched::ObjectQueue.find_or_create @user, "www.budsgunshop.com/product_links"
        expect(object_q.size).to be_zero

        ssn = Stretched::Session.new(@user, @sessions.last)
        result = Stretched::RunSession.perform(stretched_session: ssn)

        expect(object_q.size).to eq(51)
        expect(result.pages_scraped).to eq(2)
      end

      it "runs a session with link expansions and extracts JSON objects from catalog pages" do
        Mocktra(@domain) do
          get '/catalog/1' do
            File.open("#{Rails.root}/spec/fixtures/web_pages/www--budsgunshop--com/1911-listing-page.html") do |file|
              file.read
            end
          end
        end

        object_q = Stretched::ObjectQueue.find_or_create @user, "www.budsgunshop.com/product_links"
        expect(object_q.size).to be_zero

        ssn = Stretched::Session.new(@user, @sessions.first)
        result = Stretched::RunSession.perform(stretched_session: ssn)
        expect(object_q.size).to eq(57)
        expect(result.pages_scraped).to eq(8)
      end
    end

    describe "product feeds" do

      before :each do
        Stretched::Registration.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
        source = YAML.load_file("#{Rails.root}/spec/fixtures/sites/stretched/ammo--net.yml")['site']['registrations']
        Stretched::Registration.register_from_source(@user, source)
        @sessions = YAML.load_file("#{Rails.root}/spec/fixtures/sites/stretched/ammo--net.yml")['site']['sessions']
      end

      it "runs a session and extracts objects from product feeds" do
        Mocktra("ammo.net") do
          get '/media/feeds/genericammofeed.xml' do
            File.open("#{Rails.root}/spec/fixtures/rss_feeds/full_product_feed.xml") do |file|
              file.read
            end
          end
        end

        object_q = Stretched::ObjectQueue.find_or_create @user, "ammo.net/listings"
        expect(object_q.size).to be_zero

        ssn = Stretched::Session.new(@user, @sessions.first)
        result = Stretched::RunSession.perform(stretched_session: ssn)
        expect(result.pages_scraped).to eq(1)
        expect(object_q.size).to eq(18)

        json = object_q.pop
        page = json.page
        expect(page.body).to be_true
        expect(page.headers).not_to be_nil
        expect(page.code).to eq(200)

        object = json.object
        expect(object.url).to include("ammo.net")
        expect(object.location).to eq("Atlanta, GA 30348")
        expect(object.price_in_cents).not_to be_nil
        expect(object.availability).not_to be_nil
        expect(object.product_category1).to eq("Ammunition")
      end
    end
  end

end
