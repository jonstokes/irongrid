require 'spec_helper'

describe ParsePagesWorker do

  it "adds a valid new page to the PPQ, and an image_url to the ImageSet" do
    pending "Example"
    # if scraper.valid?
    #   PPQ << { url: url, source: nil, attributes: scraper.listing }
    #   IS << url
  end

  it "adds a valid existing page to the PPQ, and an image_url to the ImageSet" do
    pending "Example"
    # if scraper.valid?
    #   PPQ << { url: url, source: nil, attributes: scraper.listing, id: id }
    #   IS << url
  end

  it "passes through a :lookup id from the PQ, and adds the image_url to the ImageSet" do
    # PPQ << { url: url, source: nil, attributes: scraper.listing, id: :lookup }
  end

  it "adds an invalid listing with an id to the DAQ for deactivation" do
    pending "Example"
    # if scraper.invalid?
    #   DAQ << { url: url, id: id }
  end

  it "does not add a duplicate digest listing to the PPQ" do
    pending "Example"
    # return if Listing.find_by_digest[scraper.digest]
  end

  it "adds a listing with an id and nil source to the DTQ for deletion" do
    pending "Example"
    # page = PageQueue.pop
    # if page[:id] && !page[:source]
    #   DTQ << { url:, url, id: page[id:] }
  end

  it "adds a sold classified listing with an id to the DTQ for deletion" do
    pending "Example"
    # DTQ << { url: url, id: page[id:] }
  end

  it "adds a sold classified listing without an id to the DTQ for deletion" do
    pending "Example"
    # DTQ << { url: url }
  end

  describe "image_source exists on CDN already" do
    it "correctly populates 'image' attribute with the CDN url for image_source" do
      pending "Example"
    end

    it "does not add the image_source url to the ImageSet for copying to the CDN" do
      pending "Example"
    end
  end

  describe "image_source does not exist on CDN already" do
    it "nils 'image' attribute" do
      pending "Example"
    end

    it "adds the image_source url to the ImageSet copying to the CDN" do
      pending "Example"
    end
  end
end
