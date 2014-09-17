require 'spec_helper'

describe "product_page.rb" do
  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_globals
    Stretched::Extension.register_all
    @runner = Stretched::Script.runner("globals/product_page")
  end

  describe "availability" do
    it "returns in_stock if the listing is classified or auction" do
      instance = Hashie::Mash.new(type: "ClassifiedListing")
      result = @runner.attributes['availability'].call(instance)
      expect(result).to eq("in_stock")
    end

    it "passes through the json value if the listing is retail" do
      instance = Hashie::Mash.new(type: "RetailListing", availability: "out_of_stock")
      result = @runner.attributes['availability'].call(instance)
      expect(result).to eq("out_of_stock")
    end
  end

  describe "product_number_of_rounds" do
    it "returns the json value if it's an integer in range" do
      instance = Hashie::Mash.new(
        product_number_of_rounds: 20
      )
      result = @runner.attributes['product_number_of_rounds'].call(instance)
      expect(result).to eq(20)
    end

    it "returns nil if the json value is an integer out of range" do
      instance = Hashie::Mash.new(
        product_number_of_rounds: 0
      )
      result = @runner.attributes['product_number_of_rounds'].call(instance)
      expect(result).to be_nil
    end

    it "returns the json value if it's string that translates to an integer in range" do
      instance = Hashie::Mash.new(
        product_number_of_rounds: "1,000"
      )
      result = @runner.attributes['product_number_of_rounds'].call(instance)
      expect(result).to eq(1000)
    end

    it "extracts the number of rounds from the title if necessary and possible" do
      instance = Hashie::Mash.new(
        title: "Box of 1,000 rounds"
      )
      result = @runner.attributes['product_number_of_rounds'].call(instance)
      expect(result).to eq(1000)
    end

    it "extracts the number of rounds from the keywords if necessary and possible" do
      instance = Hashie::Mash.new(
        keywords: "1000rds"
      )
      result = @runner.attributes['product_number_of_rounds'].call(instance)
      expect(result).to eq(1000)
    end
  end

  describe "product_grains" do
    it "returns the json value if it's an integer in range" do
      instance = Hashie::Mash.new(
        product_grains: 20
      )
      result = @runner.attributes['product_grains'].call(instance)
      expect(result).to eq(20)
    end

    it "returns nil if the json value is an integer out of range" do
      instance = Hashie::Mash.new(
        product_grains: 0
      )
      result = @runner.attributes['product_grains'].call(instance)
      expect(result).to be_nil
    end

    it "returns the json value if it's string that translates to an integer in range" do
      instance = Hashie::Mash.new(
        product_grains: "200"
      )
      result = @runner.attributes['product_grains'].call(instance)
      expect(result).to eq(200)
    end

    it "extracts the grains from the title if necessary and possible" do
      instance = Hashie::Mash.new(
        title: "100gr"
      )
      result = @runner.attributes['product_grains'].call(instance)
      expect(result).to eq(100)
    end

    it "extracts the grains from the keywords if necessary and possible" do
      instance = Hashie::Mash.new(
        keywords: "100 grain"
      )
      result = @runner.attributes['product_grains'].call(instance)
      expect(result).to eq(100)
    end
  end

  describe "product_caliber" do
    it "extracts the caliber from the product_caliber field" do
      instance = Hashie::Mash.new(product_caliber: "Caliber: 9mm")
      result = @runner.attributes['product_caliber'].call(instance)
      expect(result).to eq("9mm Luger")
    end

    it "extracts the caliber from the title field" do
      instance = Hashie::Mash.new(
        product_caliber: "Caliber: foobar",
        title: "Federal 9mm ammo"
      )
      result = @runner.attributes['product_caliber'].call(instance)
      expect(result).to eq("9mm Luger")
    end

    it "extracts the caliber from the keywords field" do
      instance = Hashie::Mash.new(
        product_caliber: "Caliber: foobar",
        title: "Federal Ammo",
        keywords: "9mm ammo"
      )
      result = @runner.attributes['product_caliber'].call(instance)
      expect(result).to eq("9mm Luger")
    end
  end

  describe "product_manufacturer" do
    it "extracts the manufacturer from the product_manufacturer field" do
      instance = Hashie::Mash.new(product_manufacturer: "Brand: S&W")
      result = @runner.attributes['product_manufacturer'].call(instance)
      expect(result).to eq("Smith & Wesson")
    end
  end
end
