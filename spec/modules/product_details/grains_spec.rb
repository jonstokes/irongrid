require 'spec_helper'

describe ProductDetails::Grains do
  describe "#parse" do
    it "extracts grains from a scrubbed string" do
      text = "9mm FMJ 62 grain"
      results = ProductDetails::Grains.parse(text)
      results[:text].should == "9mm FMJ 62 grain"
      results[:keywords].should == [62]
    end

    it "returns empty keywords array if no grains were found" do
      text = "9mm FMJ"
      results = ProductDetails::Grains.parse(text)
      results[:text].should == "9mm FMJ"
      results[:keywords].should == []
    end
  end
end
