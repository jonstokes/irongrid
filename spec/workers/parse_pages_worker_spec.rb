require 'spec_helper'

describe ParsePagesWorker do

  it "adds a page to the PPQ, and an image_url to the ImageSet" do
    pending "Example"
  end

  it "does not add a duplicate digest to the PPQ" do
    pending "Example"
  end

  it "adds an invalid retail listing with an id to the DDQ for deactivation" do
    pending "Example"
  end

  it "adds a sold classified listing with an id to the DDQ for deletion" do
    pending "Example"
  end

  it "adds a sold classified listing without an id to the DDQ for deletion if its in the db" do
    pending "Example"
  end

  describe "image_source exists on CDN already" do
    it "correctly populates 'image' attribute with the CDN url for image_source" do
      pending "Example"
    end

    it "does not add the image_source url to the ImageSet" do
      pending "Example"
    end
  end

  describe "image_source does not exist on CDN already" do
    it "nils 'image' attribute" do
      pending "Example"
    end

    it "adds the image_source url to the ImageSet for download/resize/upload" do
      pending "Example"
    end
  end
end
