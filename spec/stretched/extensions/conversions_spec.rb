require 'spec_helper'

describe "conversions.rb" do
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

  describe "calculate_discount_in_cents" do
    it "returns nil if there is no price or current_price" do
      instance = Hashie::Mash.new
      result = @runner.calculate_discount_in_cents(instance)
      expect(result).to be_nil
    end

    it "returns nil if there is no discount" do
      instance = Hashie::Mash.new(price_in_cents: 100, current_price_in_cents: 100)
      result = @runner.calculate_discount_in_cents(instance)
      expect(result).to be_nil
    end

    it "returns a discount if there is one" do
      instance = Hashie::Mash.new(price_in_cents: 100, current_price_in_cents: 90)
      result = @runner.calculate_discount_in_cents(instance)
      expect(result).to eq(10)
    end
  end

  describe "calculate_percent_discount" do
    it "returns nil if there is no discount_in_cents" do
      instance = Hashie::Mash.new
      result = @runner.calculate_discount_percent(instance)
      expect(result).to be_nil
    end

    it "returns a discount if there is one" do
      instance = Hashie::Mash.new(price_in_cents: 100, discount_in_cents: 10)
      result = @runner.calculate_discount_percent(instance)
      expect(result).to eq(10)
    end
  end

end
