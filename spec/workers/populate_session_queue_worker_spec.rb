require 'spec_helper'
require 'sidekiq/testing'

describe PopulateSessionQueueWorker do
  before :each do
    # Sidekiq
    Sidekiq::Testing.disable!
    clear_sidekiq

    # Stretched
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals

    # IronGrid
    @site = create_site "www.retailer.com"
    LinkMessageQueue.new(domain: @site.domain).clear
    ImageQueue.new(domain: @site.domain).clear
    CDN.clear!

    # Vars
    @worker = PopulateSessionQueueWorker.new
    @session_q = Stretched::SessionQueue.find_or_create(@site.domain)
  end

  after :each do
    clear_sidekiq
    Sidekiq::Testing.fake!
  end

  describe "#perform" do

    it "pushes a site's sessions to the correct SNQ" do
      pending "Example"
    end

    it "marks site as read" do
      pending "Example"
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

