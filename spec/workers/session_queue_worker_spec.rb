require 'spec_helper'
require 'sidekiq/testing'

describe SessionQueueWorker do
  describe "#perform" do
    it "pushes all of a site's sessions into the SNQ" do
      # load site with sessions
      # push all the sessions to the SNQ
      pending "Example"
    end
  end
end
