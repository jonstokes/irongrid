require 'spec_helper'

describe ScrapePagesWorker do

  describe "#perform" do

    it "pops links from the LinkSet and pulls the page" do
      pending "Example"
    end

    it "correctly tags a 404 link in Redis" do
      pending "Example"
    end

    it "correctly tags a not_found link in Redis" do
      pending "Example"
    end

    it "correctly tags an invalid link in Redis" do
      pending "Example"
    end

    it "correctly tags a valid link in Redis" do
      pending "Example"
    end

    it "adds digests and attrs to Redis for valid links" do
      pending "Example"
    end

    describe "where image_source exists on CDN already" do
      it "correctly populates 'image' attribute with the CDN url for image_source" do
        pending "Example"
      end

      it "does not add the image_source url to the ImageSet for copying to the CDN" do
        pending "Example"
      end
    end

    describe "where image_source does not exist on CDN already" do
      it "nils 'image' attribute" do
        pending "Example"
      end

      it "adds the image_source url to the ImageSet copying to the CDN" do
        pending "Example"
      end
    end
  end

  describe "#transition" do
    it "transitions to self if it times out while the site's LinkSet is not empty" do
      pending "Example"
    end

    it "transitions to RefreshLinksWorker if the site's LinkSet is empty and the site hasn't been read recently" do
      pending "Example"
    end
  end
end
