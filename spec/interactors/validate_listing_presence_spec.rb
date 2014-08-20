require 'spec_helper'

describe ValidateListingPresence do
  describe "#perform" do
    it "returns true if the page was found" do
      json = Hashie::Mash.new(
        listing_json: {},
        page: {
          fetched: true,
          body: true,
          code: 200
        }
      )
      result = ValidateListingPresence.perform(json)
      expect(result.success?).to be_true
    end

    it "returns false if the page was not found" do
      json = Hashie::Mash.new(
        listing_json: {},
        page: {
          fetched: false,
          body: false,
          code: 404
        }
      )
      result = ValidateListingPresence.perform(json)
      expect(result.success?).to be_false
    end

    it "returns false if the listing was not found" do
      json = Hashie::Mash.new(
        listing_json: {
          not_found: true
        },
        page: {
          fetched: true,
          body: true,
          code: 200
        }
      )
      result = ValidateListingPresence.perform(json)
      expect(result.success?).to be_false
    end
  end
end
