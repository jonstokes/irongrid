require 'spec_helper'
require 'sidekiq/testing'

describe PopulateSessionQueueWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # Stretched
    Stretched::Registration.clear_all
    register_stretched_globals

    # IronGrid
    @site = create_site "www.budsgunshop.com"
    LinkMessageQueue.new(domain: @site.domain).clear

    # Vars
    @worker = PopulateSessionQueueWorker.new
    @session_q = Stretched::SessionQueue.find_or_create(@site.domain)
    @session_q.clear
    @url = "http://#{@site.domain}/1"
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do

    it "pushes a site's sessions to the correct SNQ" do
      @worker.perform(domain: @site.domain)
      expect(@session_q.size).to eq(5)
    end

    it "marks site as read" do
      expect(@site.read_at).to be_nil
      @worker.perform(domain: @site.domain)
      puts "#{@site.read_at}"
      expect(Site.new(domain: @site.domain, source: :redis).read_at).not_to be_nil
    end

    it "does nothing if the site's product link queue is populated" do
      obq = Stretched::ObjectQueue.new("#{@site.domain}/product_links")
      object = {
        session: {},
        page: { url: @url },
        object: { url: @url }
      }
      obq.push object
      @worker.perform(domain: @site.domain)
      expect(@session_q.size).to be_zero
    end

    it "does nothing if the site's LMQ is populated" do
      LinkMessageQueue.new(domain: @site.domain).add(LinkMessage.new(url: @url))
      @worker.perform(domain: @site.domain)
      expect(@session_q.size).to be_zero
    end

    describe "does nothing if any part of the prune-refresh-push cycle is in effect" do
      it "does nothing of the site's PruneLinksWorker is running" do
        PruneLinksWorker.perform_async(domain: @site.domain)
        @worker.perform(domain: @site.domain)
        expect(@session_q.size).to be_zero
      end
      it "does nothing of the site's RefreshLinksWorker is running" do
        RefreshLinksWorker.perform_async(domain: @site.domain)
        @worker.perform(domain: @site.domain)
        expect(@session_q.size).to be_zero
      end
      it "does nothing of the site's PushLinksWorker is running" do
        PushProductLinksWorker.perform_async(domain: @site.domain)
        @worker.perform(domain: @site.domain)
        expect(@session_q.size).to be_zero
      end
    end
  end

end

