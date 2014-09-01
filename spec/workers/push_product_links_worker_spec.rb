require 'spec_helper'
require 'sidekiq/testing'

describe PushProductLinksWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # Stretched
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals
    register_site "www.budsgunshop.com"

    # IronGrid
    @site = create_site "www.budsgunshop.com"
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!

    # Vars
    @worker = PushProductLinksWorker.new
    @page = {
      url:     "http://#{@site.domain}/catalog/1",
      headers: "",
      code:    200,
      body:    true,
      error:   nil,
      fetched: true,
      response_time: 100
    }
    @object = {
      session: {},
      page: @page,
      object: { product_link: "http://#{@site.domain}/1" }
    }
    @object_q = Stretched::ObjectQueue.find_or_create("#{@site.domain}/product_links")
    @session_q = Stretched::SessionQueue.find_or_create("#{@site.domain}")
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do

    it "pops a product link from the OBQ and pushes it to the SNQ" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(@object_q.size).to be_zero
      expect(@session_q.size).to eq(1)

      ssn = @session_q.pop
      expect(ssn.queue_name).to eq("www.budsgunshop.com")
      expect(ssn.session_definition.key).to eq("globals/standard_html_session")
      expect(ssn.object_adapters.count).to eq(1)
      expect(ssn.urls.count).to eq(1)
    end

    it "merges in stale listings for this domain" do
      stale_listing = FactoryGirl.create(:retail_listing, seller_domain: @site.domain, updated_at: Time.now - 5.days)
      5.times { FactoryGirl.create(:retail_listing, seller_domain: @site.domain, updated_at: Time.now - 5.days) }
      FactoryGirl.create(:retail_listing, seller_domain: @site.domain, updated_at: Time.now)

      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(@object_q.size).to be_zero
      expect(@session_q.size).to eq(1)

      ssn = @session_q.pop
      expect(ssn.queue_name).to eq("www.budsgunshop.com")
      expect(ssn.session_definition.key).to eq("globals/standard_html_session")
      expect(ssn.object_adapters.count).to eq(1)
      expect(ssn.urls.count).to eq(6)

    end
  end

  describe "#transition" do
    it "transitions to self if it times out while the site's ObjectQueue is not empty" do
      pending "Example"
    end

    it "does not transition to self if the site's ObjectQueue is empty" do
      pending "Example"
    end
  end

end

