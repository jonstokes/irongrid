require 'spec_helper'

describe CreateUpdateListingsWorker do
  describe "#perform" do

    describe "create new listings" do
      it "creates a new listing when parsed page has no id field" do
        pending "Example"
        # page = ppq.pop
        # if !page[:id]
        #   listing.create(attrs)
      end

      it "creates a new listing when parsed page's :id field has a :lookup directive but find_by_url fails" do
        pending "Example"
        # page = ppq.pop
        # if page[:id] == :lookup
        #   listing = Listing.find_by_url page[:url]
        #   if listing.nil?
        #     Listing.create(page[:attrs])
      end
    end

    describe "update existing listings" do
      it "updates an existing listing when parsed page has an id field" do
        pending "Example"
        # page = ppq.pop
        # if page[:id].is_a?(Integer)
        #   listing = Listing.find page[:id]
        #   listing.update(attrs)
      end

      it "updates an exiting listing by looking up the id when parsed page has an id field with lookup directive" do
        pending "Example"
        # page = ppq.pop
        # if page[:id] == :lookup
        #   listing = Listing.find_by_url page[:url]
        #   listing.update(page[:attrs])
      end
    end
  end
end
