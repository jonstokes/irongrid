require 'spec_helper'

describe CreatePagesWorker do

  before :all do
    PageQueue.mock!
  end

  after :all do
    PageQueue.stop_mocking!
  end

  before :each do
    @worker = CreatePagesWorker.new
  end

  describe "#perform" do
    it "will not start if another worker is reading this domain" do
      pending "Example"
    end

    describe "new listings" do
      it "adds pages to the PQ from new links in a site's LinkSet" do
        pending "Example"
        # PQ << { url: url, source: html, format: html }
      end
    end

    describe "listings that are already in the database" do
      it "adds pages to the PQ from existing links in a site's LinkSet" do
        pending "Example"
        # PQ << { url: url, id: id, source: html, format: html }
      end

      it "sets source to nil in PageQueue for pages where url has 404'd and id is not nil" do
        # if it pops a link from the link_set like {id: "1234", url: "http://foo.com/"}
        #   and the link 404's then it should push {id: "1234", url: "http://foo.com/", source: nil, format: nil} to the PQ
        #
      end
    end

  end
end
