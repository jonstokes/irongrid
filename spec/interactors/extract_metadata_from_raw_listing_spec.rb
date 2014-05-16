require 'spec_helper'

describe ExtractMetadataFromRawListing do
  describe "#perform" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @category1 = ElasticSearchObject.new(
        "category1",
        raw: "Ammunition",
        classification_type: "hard"
      )
      @raw_listing = {
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
      }
    end

    it "correctly extracts the manufacturer from the raw_listing if it's explicit there" do
      @raw_listing.merge!(
        "title" => "Ammo, 420 Rounds",
        "manufacturer" => "Mfgr: Federal"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.manufacturer.raw).to eq("Federal")
      expect(result.manufacturer.classification_type).to eq("hard")
    end

    it "correctly hard classifieds the caliber_category" do
      @raw_listing.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "caliber_category" => "rifle"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("rifle")
      expect(result.caliber_category.classification_type).to eq("hard")
    end

    it "correctly extracts the caliber when it's explicitly present in raw_listing" do
      @raw_listing.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "caliber" => "Caliber: 20ga"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.caliber.raw).to eq("20 gauge")
      expect(result.caliber.classification_type).to eq("hard")
    end

    it "correctly extracts the number of rounds from the raw_listing when it's present there" do
      @raw_listing.merge!(
        "title" => "Federal XM855 .44 FMJ",
        "number_of_rounds" => "420",
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.number_of_rounds.raw).to eq(420)
      expect(result.number_of_rounds.classification_type).to eq("hard")
    end

    it "correctly extracts the grains from the raw_listing if it's present there" do
      @raw_listing.merge!(
        "title" => "Federal XM855 .44 FMJ",
        "grains" => "62",
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.grains.raw).to eq(62)
      expect(result.grains.classification_type).to eq("hard")
    end

    it "correctly soft classifies the caliber_category as rifle" do
      @raw_listing.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "caliber" => "Caliber: .223 Remington"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("rifle")
      expect(result.caliber_category.classification_type).to eq("metadata")
    end

    it "correctly soft classifies the caliber_category as shotgun" do
      @raw_listing.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "caliber" => "Caliber: 20ga"
      )
      result = ExtractMetadataFromRawListing.perform(
        raw_listing: @raw_listing,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("shotgun")
      expect(result.caliber_category.classification_type).to eq("metadata")
    end

  end
end
