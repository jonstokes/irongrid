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



  end
end
