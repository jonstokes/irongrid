require 'spec_helper'

describe ElasticSearchObject do
  describe "#initialize" do
    it "creates a new ElasticSearchObject with the proper data" do
      title = ElasticSearchObject.new("title", raw: "Foobar")
      expect(title).to be_a(ElasticSearchObject)
      expect(title.raw).to eq("Foobar")
    end

    it "should blow up if a field is invalid" do
      expect {
        ElasticSearchObject.new(
          "category1",
          raw: "Guns",
          classificatio_type: "hard"
        )
      }.to raise_error
    end

    it "should blow up if a classification_type is invalid" do
      expect {
        ElasticSearchObject.new(
          "category1",
          raw: "Guns",
          classification_type: "harrrd"
        )
      }.to raise_error
    end

    it "blows up if the name is invalid" do
      expect {
        ElasticSearchObject.new("category")
      }.to raise_error
    end
  end

  describe "#field=" do
    it "assigns a value to a field" do
      category1 = ElasticSearchObject.new("category1", raw: "Foobar")
      category1.classification_type = "hard"
      expect(category1.classification_type).to eq("hard")
    end

    it "blows up if a field value is invalid" do
      category1 = ElasticSearchObject.new("category1", raw: "Foobar")
      expect {
        category1.classification_type = "harrrd"
      }.to raise_error
    end
  end

  describe "#to_index_format" do
    it "outputs the object in a format that's ready to be converted to json and indexed" do
      title = ElasticSearchObject.new("title", raw: "Foobar", normalized: "foobar")
      expect(title.to_index_format).to eq(
        [
          {"title" => "Foobar"},
          {"normalized" => "foobar"},
        ]
      )
    end

    it "outputs as a string an object that's not mapped as an object in the ES index" do
      keywords = ElasticSearchObject.new("keywords", raw: "Foobar", normalized: "foobar")
      expect(keywords.to_index_format).to eq("Foobar")
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
