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
    @worker = PullProductLinksWorker.new
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
    @object_q.clear
    @link_store = LinkMessageQueue.new(domain: @site.domain)
    @link_store.clear
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do

    it "pops a product link from the OBQ and pushes it to the LMQ" do
      @object_q.add(@object)
      @worker.perform(domain: @site.domain)
      expect(@object_q.size).to be_zero
      expect(@link_store.size).to eq(1)

      msg = @link_store.pop
      expect(msg.url).to eq("http://#{@site.domain}/1")
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

