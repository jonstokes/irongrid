require 'spec_helper'

describe ProductDetails::Rounds do
  describe "#parse" do
    it "parses round from a string" do
      text = "9mm FMJ 200rnds"
      results = ProductDetails::Scrubber.scrub(text, :rounds)
      results = ProductDetails::Rounds.parse(results)
      results[:text].should == "9mm FMJ 200 rounds"
      results[:keywords].first.should == 200
    end
  end
end
