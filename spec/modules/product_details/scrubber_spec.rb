require 'spec_helper'

describe ProductDetails::Scrubber do

  describe "#scrub_rounds" do
    it "scrubs rounds from a string" do
      text = "9mm FMJ 200rnds"
      ProductDetails::Scrubber.scrub(text, :rounds).should == "9mm FMJ 200 rounds"
    end
  end

  describe "#scrub_grains" do
    it "scrubs grains from a string" do
      text = "9mm FMJ 62gr"
      ProductDetails::Scrubber.scrub(text, :grains).should == "9mm FMJ 62 grain"
    end

    it "does not modify the input string" do
      text = "9mm FMJ 62gr"
      ProductDetails::Scrubber.scrub(text, :grains)
      text.should == "9mm FMJ 62gr"
    end

    it "returns the original text if there was nothing to do" do
      text = "9mm FMJ"
      ProductDetails::Scrubber.scrub(text, :grains).should == "9mm FMJ"
    end
  end

  describe "#scrub_caliber" do
    it "scrubs a standard pistol caliber without a dot" do
      ProductDetails::Scrubber.scrub("45acp", :caliber).should == ".45 acp"
    end

    it "scrubs a standard pistol caliber with a dot" do
      ProductDetails::Scrubber.scrub(".38 spc", :caliber).should == ".38 Special"
    end

    it "scrubs a standard pistol caliber with a dash" do
      ProductDetails::Scrubber.scrub("38-spc", :caliber).should == ".38 Special"
    end

    it "scrubs a standard pistol caliber without a space" do
      ProductDetails::Scrubber.scrub("38spc", :caliber).should == ".38 Special"
    end

    it "scrubs a +P round" do
      ProductDetails::Scrubber.scrub("9mm+P", :caliber).should == "9mm +P"
    end

  end

  describe "#scrub_rounds" do
    it "scrubs rounds" do
      ProductDetails::Scrubber.scrub("100rd", :rounds).should == "100 round"
      ProductDetails::Scrubber.scrub("100rds", :rounds).should == "100 rounds"
      ProductDetails::Scrubber.scrub("100rnd", :rounds).should == "100 round"

      ProductDetails::Scrubber.scrub("100 rd", :rounds).should == "100 round"
      ProductDetails::Scrubber.scrub("100 rds", :rounds).should == "100 rounds"
      ProductDetails::Scrubber.scrub("100 rnd", :rounds).should == "100 round"

      ProductDetails::Scrubber.scrub("100-rd", :rounds).should == "100 round"
      ProductDetails::Scrubber.scrub("100-rds", :rounds).should == "100 rounds"
      ProductDetails::Scrubber.scrub("100-rnd", :rounds).should == "100 round"

      ProductDetails::Scrubber.scrub("100 Rd", :rounds).should == "100 round"
      ProductDetails::Scrubber.scrub("100 Rds", :rounds).should == "100 rounds"
      ProductDetails::Scrubber.scrub("100 Rnd", :rounds).should == "100 round"
    end

    it "scrubs rounds with commas" do
      ProductDetails::Scrubber.scrub("1,000rd", :rounds).should == "1000 round"
    end

    it "scrubs 'box of rounds' type entries" do
      ProductDetails::Scrubber.scrub("box of 500", :rounds).should == "500 rounds"
      ProductDetails::Scrubber.scrub("box of 5,000", :rounds).should == "5000 rounds"
      ProductDetails::Scrubber.scrub("Federal XM855 .22 LR 62 Grain FMJ, box of 4,000", :rounds).should == "Federal XM855 .22 LR 62 Grain FMJ, 4000 rounds"
    end

    it "does not modify the input string" do
      text = "9mm FMJ 200rnds"
      ProductDetails::Scrubber.scrub_all(text)
      text.should == "9mm FMJ 200rnds"
    end
  end
end
