require 'spec_helper'

describe SetCurrentPrice do
  describe "#perform" do
    it "sets the current price for a retail listing" do
      opts = {
        :price_in_cents => 65000,
        :sale_price_in_cents => 60000,
        :type => "RetailListing"
      }
      result = SetCurrentPrice.perform(opts)
      expect(result.current_price_in_cents).to eq(60000)
    end

    it "sets the current price for an classified listing" do
      opts = {
        :price_in_cents => 65000,
        :sale_price_in_cents => nil,
        :type => "ClassifiedListing"
      }
      result = SetCurrentPrice.perform(opts)
      expect(result.current_price_in_cents).to eq(65000)
    end

    it "sets the current price for a auction listing" do
      opts = {
        :buy_now_price_in_cents => 1,
        :minimum_bid_in_cents => 2,
        :reserve_in_cents => 3,
        :current_bid_in_cents => 4,
        :type => "AuctionListing"
      }
      result = SetCurrentPrice.perform(opts)
      expect(result.current_price_in_cents).to eq(4)
    end
  end
end
