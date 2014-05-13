require 'spec_helper'

describe ElasticSearchObject do
  describe "#initialize" do
    it "creates a new ElasticSearchObject with the proper data" do
      title = ElasticSearchObject.new("title", raw: "Foobar")
      expect(title).to be_a(ElasticSearchObject)
      expect(title.raw).to eq("Foobar")
    end
  end

  describe "#to_a" do
    it "outputs the object in a format that's ready to be converted to json and indexed" do
      title = ElasticSearchObject.new("title", raw: "Foobar", normalized: "foobar")
      expect(title.to_a).to eq(
        [
          {"title" => "Foobar"},
          {"scrubbed" => nil},
          {"normalized" => "foobar"},
          {"autocomplete" => nil}
        ]
      )
    end

    it "outputs as a string an object that's not mapped as an object in the ES index" do
      keywords = ElasticSearchObject.new("keywords", raw: "Foobar", normalized: "foobar")
      expect(keywords.to_a).to eq("Foobar")
    end
  end

  describe "#digest_string" do
    it "outputs an ordered digest string" do
      title = ElasticSearchObject.new("title", raw: "Foobar", autocomplete: "barfoo", normalized: "foobar")
      expect(title.digest_string).to eq("Foobarfoobarbarfoo")
    end
  end

  describe "#to_s" do
    it "yields the raw value of the object" do
      title = ElasticSearchObject.new("title", raw: "Foobar")
      expect(title.to_s).to eq("Foobar")
    end
  end
end
