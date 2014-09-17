require 'spec_helper'

describe "product_page.rb" do
  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_globals
    Stretched::Extension.register_all
  end

  describe "availability" do
    it "returns in_stock if the listing is classified or auction" do
      runner = Stretched::Script.runner("globals/product_page")
      instance = Hashie::Mash.new(type: "ClassifiedListing")
      result = runner.attributes['availability'].call(instance)
      expect(result).to eq("in_stock")
    end

    it "passes through the json value if the listing is retail" do
      runner = Stretched::Script.runner("globals/product_page")
      instance = Hashie::Mash.new(type: "RetailListing", availability: "out_of_stock")
      result = runner.attributes['availability'].call(instance)
      expect(result).to eq("out_of_stock")
    end

  end
end
