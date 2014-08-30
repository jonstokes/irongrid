require 'spec_helper'

describe PopulateSessionQueueWorker do
  before :each do
    # Stretched
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals

    # IronGrid
    @site = create_site "www.retailer.com"

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

    it "does nothing if the site's SessionQueue is not empty" do
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

