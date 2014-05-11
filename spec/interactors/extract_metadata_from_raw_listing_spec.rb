require 'spec_helper'

describe ExtractMetadataFromRawListing do
  describe "#perform" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
        "category1" => "Ammunition"
      }
    end

    it "correctly extracts the manufacturer from the raw_listing if it's explicit there" do
      @raw_listing.merge!(
        "title" => "Ammo, 420 Rounds",
        "manufacturer" => "Mfgr: Federal"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
      )
      clean_listing.to_h['item_data']['manufacturer'].should == [{"manufacturer"=>"Federal"}, {"classification_type"=>"hard"}]
    end


  end
end
