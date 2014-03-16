require 'spec_helper'

describe ProductDetails::Caliber do

  describe "#parse" do
    it "extracts the caliber text from as string" do
      results = ProductDetails::Caliber.parse("This is a story about a 20 gauge gun")
      results[:text] = "This is a story about a 20 gauge gun"
      results[:keywords].should == ["20 gauge"]
    end

    it "categorizes a normalized handgun caliber" do
      results = ProductDetails::Caliber.parse("here is .45 acp")
      results[:category].should == 'handgun'
      results[:keywords].should == ['.45 ACP']
    end

    it "categorizes a normalized rifle caliber" do
      results = ProductDetails::Caliber.parse("here is .300 blk")
      results[:category].should == 'rifle'
      results[:keywords].should == ['.300 BLK']
    end

    it "categorizes a normalized shotgun gauge" do
      results = ProductDetails::Caliber.parse("here is 20 gauge")
      results[:category].should == 'shotgun'
      results[:keywords].should == ['20 gauge']
    end

    it "categorizes a normalized rimfire caliber" do
      results = ProductDetails::Caliber.parse("here is .22lr")
      results[:category].should == 'rimfire'
      results[:keywords].should == ['.22lr']
    end
  end
end
