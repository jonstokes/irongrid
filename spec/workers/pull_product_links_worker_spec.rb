require 'spec_helper'
require 'sidekiq/testing'

describe PullProductLinksWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    @site = create_site "www.budsgunshop.com"
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
    @site.product_links_queue.clear
    @link_store = LinkMessageQueue.new(domain: @site.domain)
    @link_store.clear
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do

    it "pops a product link from the OBQ and pushes it to the LMQ" do
      @site.product_links_queue.add(@object)
      @worker.perform(domain: @site.domain)
      expect(@site.product_links_queue.size).to be_zero
      expect(@link_store.size).to eq(1)

      msg = @link_store.pop
      expect(msg.url).to eq("http://#{@site.domain}/1")
    end
  end

  describe "#transition" do
    it "transitions to self if it times out while the site's ObjectQueue is not empty" do
      pending "Example"
      expect(true).to eq(false)
    end

    it "does not transition to self if the site's ObjectQueue is empty" do
      pending "Example"
      expect(true).to eq(false)
    end
  end

end

