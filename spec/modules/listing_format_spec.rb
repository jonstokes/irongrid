require 'spec_helper'

describe ListingFormat do
  describe "#price" do
    it "should convert $1,000.99 to 100099" do
      ListingFormat.price("$1,000.00").should == 100000
    end

    it "should convvert $ 100 to 10000" do
      ListingFormat.price("$ 100").should == 10000
    end

    it "should convvert $ 1,000 to 100000" do
      ListingFormat.price("$ 1,000").should == 100000
    end

    it "should convvert $100. to 10000" do
      ListingFormat.price("$100.").should == 10000
    end

    it "should convvert $1,900. to 190000" do
      ListingFormat.price("$1,900.").should == 190000
    end

    it "should convvert $100.9 to 10090" do
      ListingFormat.price("$100.9").should == 10090
    end

    it "should covert $900.00. to 90000" do
      ListingFormat.price("$900.00.").should == 90000
    end
  end
end
