require 'spec_helper'

describe ProductDetails::ExtractMetadataFromRawListing do
  describe "#perform" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @category1 = ElasticSearchObject.new(
        "category1",
        raw: "Ammunition",
        classification_type: "hard"
      )
      @listing_json = Hashie::Mash.new(
        "title" => "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        "url" => @url,
      )
    end

    it "correctly extracts the manufacturer from the listing_json if it's explicit there" do
      @listing_json.merge!(
        "title" => "Ammo, 420 Rounds",
        "product_manufacturer" => "Mfgr: Federal"
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.manufacturer.raw).to eq("Federal")
      expect(result.manufacturer.classification_type).to eq("hard")
    end

    it "correctly hard classifieds the caliber_category" do
      @listing_json.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "product_caliber_category" => "rifle"
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("rifle")
      expect(result.caliber_category.classification_type).to eq("hard")
    end

    it "correctly extracts the caliber when it's explicitly present in listing_json" do
      @listing_json.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "product_caliber" => "Caliber: 20ga"
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.caliber.raw).to eq("20 gauge")
      expect(result.caliber.classification_type).to eq("hard")
    end

    it "correctly extracts the number of rounds from the listing_json when it's present there" do
      @listing_json.merge!(
        "title" => "Federal XM855 .44 FMJ",
        "product_number_of_rounds" => 420,
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.number_of_rounds.raw).to eq(420)
      expect(result.number_of_rounds.classification_type).to eq("hard")
    end

    it "correctly extracts the grains from the listing_json if it's present there" do
      @listing_json.merge!(
        "title" => "Federal XM855 .44 FMJ",
        "product_grains" => 62,
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.grains.raw).to eq(62)
      expect(result.grains.classification_type).to eq("hard")
    end

    it "correctly soft classifies the caliber_category as rifle" do
      @listing_json.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "product_caliber" => "Caliber: .223 Remington"
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("rifle")
      expect(result.caliber_category.classification_type).to eq("hard")
    end

    it "correctly soft classifies the caliber_category as shotgun" do
      @listing_json.merge!(
        "title" => "Federal Ammo, 420 Rounds",
        "product_caliber" => "Caliber: 20ga"
      )
      result = ProductDetails::ExtractMetadataFromRawListing.perform(
        listing_json: @listing_json,
        category1: @category1
      )
      expect(result.caliber_category.raw).to eq("shotgun")
      expect(result.caliber_category.classification_type).to eq("hard")
    end

  end
end
