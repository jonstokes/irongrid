require 'spec_helper'

describe ReadListingLinkWorker do

  describe "#perform" do
    it { should be_processed_in :db_fast }

    it "pulls the id and digest for an existing link and puts it in the LinkSet" do
      pending "Example"
    end

    it "puts a new link into the LinkSet with no id or digest" do
      pending "Example"
    end
  end
end
