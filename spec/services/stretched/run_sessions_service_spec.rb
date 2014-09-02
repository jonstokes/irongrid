require 'spec_helper'
require 'sidekiq/testing'

describe Stretched::SessionQueueService do
  before :each do
    # Stretched
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    register_stretched_globals
    register_site "www.budsgunshop.com"

    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # IronGrid
    @sessions = YAML.load_file("#{Figaro.env.sites_repo}/sites/www--budsgunshop--com.yml")['sessions']
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  it "should use DMS" do
    pending "Example"
  end

  describe "PopulateSessionQueue sites", no_es: true do
    before :each do
      @site = create_site "www.budsgunshop.com"
      @service = Stretched::SessionQueueService.new
      @q = Stretched::SessionQueue.new(@site.domain)
      @q.clear
    end

    it "starts a Stretched::RunSessionsWorker job if there are any sessions in a session queue" do
      @q.add @sessions
      @service.start
      @service.stop
      expect(Stretched::RunSessionsWorker.jobs_in_flight_with_session_queue(@site.domain).size).to eq(1)
    end

    it "does not start a Stretched::RunSessionsWorker for a site if its session q is empty" do
      @service.start
      @service.stop
      expect(Stretched::RunSessionsWorker.jobs_in_flight_with_session_queue(@site.domain)).to be_empty
    end

    it "should not generate a PopulateSessionQueue for a site if the site has RSW's in progress" do
      @q.add @sessions
      Stretched::RunSessionsWorker.perform_async(domain: @site.domain)
      @service.start
      @service.stop
      expect(Stretched::RunSessionsWorker.jobs_in_flight_with_session_queue(@site.domain).size).to eq(1)
    end

  end
end
