require 'spec_helper'

describe ExtractMetadataFromSourceAttributes do
  describe "#perform" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @category1 = ElasticSearchObject.new(
        "category1",
        raw: "Ammunition",
        classificatio_type: "hard"
      )
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
      }
    end

    describe "manufacturer" do
      it "correctly extracts the manufacturer from the title" do
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
      end

      it "correctly extracts the manufacturer from the keywords" do
        @raw_listing.merge!(
          "title" => "Ammo, 420 Rounds",
          "keywords" => "Federal"
        )
        clean_listing = RetailListingCleaner.new(raw_listing: @raw_listing, url: @url, site: @site)
        clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"metadata"}]
      end
    end



  end
end
