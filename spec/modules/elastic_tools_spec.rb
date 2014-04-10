require 'spec_helper'

describe ElasticTools do
  describe ElasticTools::Analyzer do
    describe "#lowercase_synonyms_filter" do
      it "should normalize calibers from text" do
        text = "This is .17 Aguila"
        ElasticTools::Analyzer.analyze(text, analyzer: :product_terms).should == "this is .17 PMC"
      end

      it "should normalize manufacturers from scrubbed text" do
        text = "This is a Lewis Machine and Tool gun"
        ElasticTools::Analyzer.analyze(text, analyzer: :product_terms).should == "this is a LMT gun"
      end
    end
  end

  describe ElasticTools::QueryPreParser do
    describe "#escape_query" do
      it "downcases logical operators" do
        query = "OR HI-POINT PISTOL AND OR NOT RIFLE AND"
        escaped_query = ElasticTools::QueryPreParser.escape_query(query)
        expect(escaped_query).to eq("or HI\\-POINT PISTOL and or not RIFLE and")
      end
    end
  end
end
