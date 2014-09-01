require 'spec_helper'

describe PushProductLinksWorker do
  before :each do
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
    @session_q = Stretched::SessionQueue.find_or_create(@site.domain)
    @link_store = LinkMessageQueue.new(domain: @site.domain)
    @msg = LinkMessage.new(url: "http://#{@site.domain}/catalog/1")
  end

  describe "#perform" do

    it "pops a product link from the LMQ and pushes it to the SNQ" do
      @link_store.add(@msg)
      @worker.perform(domain: @site.domain)
      expect(@link_store.size).to be_zero
      expect(@session_q.size).to eq(1)

      ssn = @session_q.pop
      expect(ssn.queue_name).to eq("www.budsgunshop.com")
      expect(ssn.session_definition.key).to eq("globals/standard_html_session")
      expect(ssn.object_adapters.count).to eq(1)
      expect(ssn.urls.count).to eq(1)
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

