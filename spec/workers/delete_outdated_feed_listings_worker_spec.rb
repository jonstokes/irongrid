require 'spec_helper'
require 'sidekiq/testing'

describe DeleteOutdatedFeedListingsWorker do
  describe "#perform#" do
    it "deletes listings for a full product feed site when those listings are older than 2X site's refresh interval" do
      pending "Example"
    end
  end
end
