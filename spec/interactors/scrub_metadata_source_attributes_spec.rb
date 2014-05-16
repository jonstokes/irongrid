require 'spec_helper'

describe ScrubMetadataSourceAttributes do
  describe "#perform" do
    it "scrubs the listing title" do
      title_text = ".40 Smith & Wesson listing title"
      title = ElasticSearchObject.new("title", raw: title_text)
      keywords = ElasticSearchObject.new("keywords", raw: nil)
      result = ScrubMetadataSourceAttributes.perform(title: title, keywords: keywords, category1: "Ammunition")
      expect(result.title.scrubbed).to eq(".40 S&W listing title")
      expect(result.title.autocomplete).to eq(".40 Smith & Wesson listing title")
    end

    it "scrubs the keywords" do
      title_text = ".40 Smith & Wesson listing title"
      keywords_text = ".40 Smith & Wesson ammo"
      title = ElasticSearchObject.new("title", raw: title_text)
      keywords = ElasticSearchObject.new("keywords", raw: keywords_text)
      result = ScrubMetadataSourceAttributes.perform(title: title, keywords: keywords, category1: "Ammunition")
      expect(result.title.scrubbed).to eq(".40 S&W listing title")
      expect(result.keywords.scrubbed).to eq(".40 S&W ammo")
    end
  end
end
