require 'spec_helper'

describe ParsePagesWorker do

  describe "#perform" do
    describe "new listings" do
      it "adds a valid new listing's attributes to the CLQ" do
        pending "Example"
        # if scraper.valid?
        #   CLQ << { url: url, source: nil, attributes: scraper.listing }
      end

      it "does not add an invalid new listing to any queue" do
        pending "Example"
      end

      it "does not add a duplicate digest listing's attributes to any queue" do
        pending "Example"
        # return if Listing.find_by_digest[scraper.digest]
      end

      it "does not add a new listing with no :source to any queue" do
        pending "Example"
      end
    end

    describe "existing listings" do
      it "adds a valid listing's parsed attributes to the ULQ" do
        pending "Example"
        # if scraper.valid?
        #   ULQ << { url: url, source: nil, attributes: scraper.listing }
      end

      it "adds an invalid listing's id to the DAQ for deactivation" do
        pending "Example"
        # DAQ << { id: listing.id }
      end

      it "adds a listing with a nil source to the DTQ for deletion" do
        # DTQ << { id: listing.id }
      end

      it "adds a sold classified listing to the DTQ for deletion" do
        pending "Example"
        # DTQ << { id: listing.id }
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
