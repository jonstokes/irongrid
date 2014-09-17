require 'spec_helper'

describe "extraction.rb" do
  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_globals
    Stretched::Extension.register_all

    @runner = Stretched::ScriptRunner.new

    # Define all extensions on the runner instance
    Stretched::Extension.registry.each_pair do |extname, block|
      @runner.instance_eval(&block)
    end
  end

  describe "extract_grains" do
    it "extracts grains from a string" do
      result = @runner.extract_grains("9mm FMJ 62gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62-gr")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 grain")
      expect(result).to eq("62")

      result = @runner.extract_grains("9mm FMJ 62 grains")
      expect(result).to eq("62")
    end
  end

  describe "extract_number_of_rounds" do

    it "extracts the number of rounds from a string" do
      @runner.extract_number_of_rounds("1,000 rounds").should == "1000"
      @runner.extract_number_of_rounds("9mm FMJ 200rnds").should == "200"
      @runner.extract_number_of_rounds("100rd").should == "100"
      @runner.extract_number_of_rounds("100rds").should == "100"
      @runner.extract_number_of_rounds("100rnd").should == "100"

      @runner.extract_number_of_rounds("100 rd").should == "100"
      @runner.extract_number_of_rounds("100 rds").should == "100"
      @runner.extract_number_of_rounds("100 rnd").should == "100"

      @runner.extract_number_of_rounds("100-rd").should == "100"
      @runner.extract_number_of_rounds("100-rds").should == "100"
      @runner.extract_number_of_rounds("100-rnd").should == "100"

      @runner.extract_number_of_rounds("100 Rd").should == "100"
      @runner.extract_number_of_rounds("100 Rds").should == "100"
      @runner.extract_number_of_rounds("100 Rnd").should == "100"
    end

    it "extracts the number of rounds from a string with commas" do
      @runner.extract_number_of_rounds("1,000rd").should == "1000"
    end

    it "extracts 'box of rounds' type entries" do
      @runner.extract_number_of_rounds("box of 500").should == "500"
      @runner.extract_number_of_rounds("box of 5,000").should == "5000"
      @runner.extract_number_of_rounds("Federal XM855 .22 LR 62 Grain FMJ, box of 4,000").should == "4000"
    end

    it "extracts 'per box' type entries" do
      @runner.extract_number_of_rounds("500 per box").should == "500"
      @runner.extract_number_of_rounds("500/box").should == "500"
      @runner.extract_number_of_rounds("500 / box").should == "500"
      @runner.extract_number_of_rounds("5,000 per box").should == "5000"
      @runner.extract_number_of_rounds("Federal XM855 .22 LR 62 Grain FMJ, 4,000 per box").should == "4000"
    end
  end

  describe "extract_metadata" do
    it "extracts a caliber from a product_caliber field" do
      instance = Hashie::Mash.new(product_caliber: "Caliber: 9mm")
      mapping = Stretched::Mapping.find("calibers")

      result = @runner.extract_metadata(:product_caliber, mapping, instance)
      expect(result).to eq("9mm Luger")
      expect(instance.product_caliber_tokens).to eq(["Caliber", ":"])
    end
  end

end
