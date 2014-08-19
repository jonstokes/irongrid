require 'spec_helper'
require 'sidekiq/testing'

describe ProductLinksWorker do
  describe "#perform" do
    it "pops 50 objects from the ProductLink OBQ" do
      pending "Example"
    end

    it "discards links that have been recently refreshed for this domain" do
      pending "Example"
    end

    it "pushes stale links back into the SNQ wrapped in the proper session object" do
      pending "Example using site.product_session_format to wrap product_link urls"
    end
  end
end
