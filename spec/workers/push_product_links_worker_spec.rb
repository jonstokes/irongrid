require 'spec_helper'
require 'sidekiq/testing'

describe PushProductLinksWorker do
  before :each do
    #Stretched
    Stretched::Registration.clear_all
    register_globals

    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # IronGrid
    @site = create_site "www.budsgunshop.com"
    @site.register
    @site.link_message_queue.clear
    @worker = PushProductLinksWorker.new
    @session_q = Stretched::SessionQueue.new(@site.domain)
    @link_store = @site.link_message_queue
    @msg = LinkMessage.new(url: "http://#{@site.domain}/catalog/1")
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
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
    it "transitions to self if it finishes while the site's LMQ is not empty" do
      400.times do |i|
        msg = LinkMessage.new(url: "http://#{@site.domain}/catalog/#{i}")
        @link_store.add(msg)
      end

      @worker.perform(domain: @site.domain)
      expect(@link_store.size).to eq(100)
      expect(@session_q.size).to eq(1)

      ssn = @session_q.pop
      expect(ssn.queue_name).to eq("www.budsgunshop.com")
      expect(ssn.session_definition.key).to eq("globals/standard_html_session")
      expect(ssn.object_adapters.count).to eq(1)
      expect(ssn.urls.count).to eq(300)

      expect(PushProductLinksWorker.jobs_in_flight_with_domain(@site.domain)).not_to be_empty
    end

    it "does not transition to self if the site's LMQ is empty" do
      200.times do |i|
        msg = LinkMessage.new(url: "http://#{@site.domain}/catalog/#{i}")
        @link_store.add(msg)
      end

      @worker.perform(domain: @site.domain)
      expect(@link_store).to be_empty
      expect(@session_q.size).to eq(1)

      ssn = @session_q.pop
      expect(ssn.queue_name).to eq("www.budsgunshop.com")
      expect(ssn.session_definition.key).to eq("globals/standard_html_session")
      expect(ssn.object_adapters.count).to eq(1)
      expect(ssn.urls.count).to eq(200)

      expect(PushProductLinksWorker.jobs_in_flight_with_domain(@site.domain)).to be_empty

    end
  end

end

