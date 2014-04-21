require 'spec_helper'

describe ProductDetails::Parser do
  describe "#parse" do
    it "should correct the case of a normalized caliber and extract it" do
      text = "this is a lmt gun"
      parser = ProductDetails::Parser.new
      results = parser.parse(text, ProductDetails::Manufacturer.dictionary)
      results[:text].should == "this is a LMT gun"
      results[:keywords].should == ["LMT"]
    end

    it "should correct and extract a caliber category" do
      text = "my handgun"
      parser = ProductDetails::Parser.new
      results = parser.parse(text, ProductDetails::Caliber.dictionaries.keys)
      results[:text].should == "my handgun"
      results[:keywords].should == ["handgun"]
    end

    it "should sort the keywords by their first appearance in the string" do
      text = "Beretta Federal"
      parser = ProductDetails::Parser.new
      results = parser.parse(text, ProductDetails::Manufacturer.dictionary)
      results[:keywords].should == ["Beretta", "Federal"]
    end

    it "should pull out only keywords that are set off by spaces or other non-word characters" do
      text = "purchasing CCI. ammo"
      parser = ProductDetails::Parser.new
      results = parser.parse(text, ProductDetails::Manufacturer.dictionary)
      results[:keywords].should include("CCI")
      results[:keywords].should_not include("ASI")
    end
  end

  describe "#parse_with_category" do
    it "should correct the case of a normalized caliber, extract it, and categorize it" do
      text = "this is a .17 pmc"
      parser = ProductDetails::Parser.new
      results = parser.parse_with_category(text, ProductDetails::Caliber.dictionaries)
      results[:text].should == "this is a .17_PMC"
      results[:keywords].should == [".17 PMC"]
      results[:category].should == 'rimfire'
    end
  end
end

