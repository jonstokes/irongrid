require 'spec_helper'

describe SetAvailability do
  describe "#perform" do
    it "returns in_stock for an in stock item" do
      raw_listing = { 'stock_status' => "In Stock" }
      result = SetAvailability.perform(
        raw_listing: raw_listing,
        type: "RetailListing"
      )
      expect(result.availability).to eq("in_stock")
    end

    it "returns out_of_stock for an in stock item" do
      raw_listing = { 'stock_status' => "Out Of Stock" }
      result = SetAvailability.perform(
        raw_listing: raw_listing,
        type: "RetailListing"
      )
      expect(result.availability).to eq("out_of_stock")
    end
  end
end
