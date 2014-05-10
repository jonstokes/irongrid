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
      expect(title.to_a).to eq([{"title" => "Foobar"},{"normalized" => "foobar"}])
    end
  end

  describe "#to_s" do
    it "yields the raw value of the object" do
      title = ElasticSearchObject.new("title", raw: "Foobar")
      expect(title.to_s).to eq("Foobar")
    end
  end
end
