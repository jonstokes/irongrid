require 'spec_helper'

describe ScrapePagesWorker do

  describe "#perform" do
    it "spawns a CreateCdnImagesWorker" do
      pending "Example"
    end

    describe "blocking" do
      it "blocks if the LinkSet is empty but there are ReadListingLinkWorker jobs in flight" do
        pending "example"
      end

      it "can time out when blocking for too long" do
        pending "example"
      end
    end

    describe "#transition" do
      it "transitions to self if it times out while the site's LinkSet is not empty" do
        pending "Example"
      end

      it "transitions to RefreshLinksWorker if the site's sets are empty and there are no read jobs in flight" do
        pending "Example"
      end
    end

    describe "possible new listings" do
      it "generates the correct WriteListingWorker for a valid listing" do
        pending "Example"
        # action: create
      end

      it "does not generate any worker for an invalid listing" do
        pending "Example"
      end

      it "does not generate any worker for a duplicate listing" do
        pending "Example"
      end

      it "does not generate any worker for an entry that 404's" do
        pending "Example"
      end
    end

    describe "existing listings" do
      it "generates the correct WriteListingWorker for a valid listing" do
        pending "Example"
        # action: update
      end

      it "generates the correct WriteListingWorker for an invalid listing" do
        pending "Example"
        # id: listing.id, action: deactivate
      end

      it "generates the correct WriteListingWorker for a url that 404s" do
        # id: listing.id, action: delete
      end

      it "generates the correct WriteListingWorker for a sold classified listing" do
        pending "Example"
        # id: listing.id, action: delete
      end
    end

    describe "for a new or updated listing where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source" do
        pending "Example"
      end

      it "does not add the image_source url to the ImageSet for copying to the CDN" do
        pending "Example"
      end
    end

    describe "for a new or updated listing where image_source does not exist on CDN already" do
      it "nils 'image' attribute" do
        pending "Example"
      end

      it "adds the image_source url to the ImageSet copying to the CDN" do
        pending "Example"
      end
    end
  end
end
