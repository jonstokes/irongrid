require 'spec_helper'

describe ValidateListingPresence do
  describe "#perform" do
    it "returns true if the page was found" do
      opts = { raw_listing: {} }
      result = ValidateListingPresence.perform(opts)
      expect(result.success?).to be_true
    end

    it "returns false if the page was not found" do
      opts = { raw_listing: { 'not_found' => 'true' } }
      result = ValidateListingPresence.perform(opts)
      expect(result.success?).to be_false
    end
  end
end
