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
      pending "example"
    end

    it "extracts the number of rounds from the keywords if necessary and possible" do
      pending "example"
    end

  end
end
