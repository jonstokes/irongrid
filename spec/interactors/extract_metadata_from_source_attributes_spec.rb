require 'spec_helper'

describe ExtractMetadataFromSourceAttributes do
  describe "#perform" do
    before :each do
      @url = "http://www.hyattgunstore.com/ammo.html"
      @category1 = ElasticSearchObject.new(
        "category1",
        raw: "Ammunition",
        classification_type: "hard"
      )

      @title_string = "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can"
      @title = ElasticSearchObject.new(
        "title",
        raw: @title_string,
        scrubbed: ProductDetails::Scrubber.scrub_all(@title_string)
      )

      @keywords_string = "Federal"
      @keywords = ElasticSearchObject.new(
        "keywords",
        raw: @keywords_string,
        scrubbed: ProductDetails::Scrubber.scrub_all(@keywords_string)
      )
    end

    describe "manufacturer" do
      it "correctly extracts the manufacturer from the title" do
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: @title
        )
        expect(result.manufacturer.raw).to eq("Federal")
        expect(result.manufacturer.classification_type).to eq("metadata")
      end

      it "correctly extracts the manufacturer from the keywords" do
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          keywords: @keywords,
          title: ElasticSearchObject.new("title", raw: "Foobar", scrubbed: "Foobar")
        )
        expect(result.manufacturer.raw).to eq("Federal")
        expect(result.manufacturer.classification_type).to eq("metadata")
      end
    end

    describe "caliber" do
      it "correctly extracts the caliber from the title" do
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: @title
        )
        expect(result.caliber.raw).to eq("5.56 NATO")
        expect(result.caliber.classification_type).to eq("metadata")

        keywords = ElasticSearchObject.new("keywords")
        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 5.56 Nato Ammo FMJ, 420 Rounds"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.caliber.raw).to eq("5.56 NATO")
        expect(result.caliber.classification_type).to eq("metadata")

        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 20ga Ammo FMJ, 420 Rounds"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.caliber.raw).to eq("20 gauge")
        expect(result.caliber.classification_type).to eq("metadata")

        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 .45acp 62 Grain FMJ, 420 Rounds"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.caliber.raw).to eq(".45 ACP")
        expect(result.caliber.classification_type).to eq("metadata")

        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 .22 LR 62 Grain FMJ, 420 Rounds"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.caliber.raw).to eq(".22lr")
        expect(result.caliber.classification_type).to eq("metadata")
      end

      it "correctly extracts the caliber from the keywords" do
        @title.raw = "Federal XM855 62 Grain FMJ, 420 Rounds"
        @title.scrubbed = ProductDetails::Scrubber.scrub_all(@title.raw)
        @keywords.raw = "Federal, 20ga"
        @keywords.scrubbed = ProductDetails::Scrubber.scrub_all(@keywords.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: @title,
          keywords: @keywords
        )
        expect(result.caliber.raw).to eq("20 gauge")
        expect(result.caliber.classification_type).to eq("metadata")
      end
    end

    describe "number of rounds" do
      it "correctly extracts the number of rounds from the title" do
        keywords = ElasticSearchObject.new("keywords")
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: @title,
          keywords: keywords
        )
        expect(result.number_of_rounds.raw).to eq(420)
        expect(result.number_of_rounds.classification_type).to eq("metadata")
      end

      it "correctly extracts the number of rounds from a 'box of rounds' type title" do
        keywords = ElasticSearchObject.new("keywords")
        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 .22 LR 62 Grain FMJ, box of 4,000"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.number_of_rounds.raw).to eq(4000)
        expect(result.number_of_rounds.classification_type).to eq("metadata")
      end

      it "correctly extracts the number of rounds from the keywords" do
        title = ElasticSearchObject.new("title")
        title.raw = "Federal XM855 .22 LR 62 Grain FMJ"
        title.scrubbed = ProductDetails::Scrubber.scrub_all(title.raw)
        keywords = ElasticSearchObject.new("keywords")
        keywords.raw = "420rnd"
        keywords.scrubbed = ProductDetails::Scrubber.scrub_all(keywords.raw)
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          title: title,
          keywords: keywords
        )
        expect(result.number_of_rounds.raw).to eq(420)
        expect(result.number_of_rounds.classification_type).to eq("metadata")
      end
    end

    describe "it can tell the difference between manufacturer and caliber" do
      it "can tell the difference between Federal as mfgr and Remington as caliber" do
        title_string = "Federal .223 Remington Ammo, 400rnds"
        title = ElasticSearchObject.new(
          "title",
          raw: title_string,
          scrubbed: ProductDetails::Scrubber.scrub_all(title_string)
        )
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          keywords: @keywords,
          title: title
        )
        expect(result.manufacturer.raw).to eq("Federal")
        expect(result.caliber.raw).to eq(".223 Rem")
      end

      it "does not misidentify Remington as a manufacturer" do
        title_string = ".223 Remington Ammo, 400rnds"
        title = ElasticSearchObject.new(
          "title",
          raw: title_string,
          scrubbed: ProductDetails::Scrubber.scrub_all(title_string)
        )
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          keywords: @keywords,
          title: title
        )
        expect(result.manufacturer.raw).to eq("Federal")
        expect(result.caliber.raw).to eq(".223 Rem")
      end

      it "does not misidentify AAC as a manufacturer" do
        title_string = ".300 aac blackout ammo, 400rnds"
        title = ElasticSearchObject.new(
          "title",
          raw: title_string,
          scrubbed: ProductDetails::Scrubber.scrub_all(title_string)
        )
        result = ExtractMetadataFromSourceAttributes.perform(
          category1: @category1,
          keywords: @keywords,
          title: title
        )
        expect(result.manufacturer.raw).to eq("Federal")
        expect(result.caliber.raw).to eq(".300 BLK")
      end
    end


  end
end
