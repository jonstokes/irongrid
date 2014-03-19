require 'spec_helper'

describe CreateUpdateListingsWorker do
  describe "#perform" do
    it "creates a new listing when parsed page's url is not in the database" do
      pending "Example"
    end

    it "updates an exiting listing after locating it by the url" do
      pending "Example"
      # page = ppq.pop
      # listing = Listing.find_by_url page[:url]
      # listing.update(page[:attrs])
    end
  end
end
