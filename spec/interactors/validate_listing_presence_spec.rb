require 'spec_helper'

describe ValidateListingPresence do

  before :each do
    create_site "www.retailer.com"
  end

  describe "#call" do
    it "returns true if the page was found" do
      json = Hashie::Mash.new(
        object: { seller_domain: "www.retailer.com" },
        page: {
          fetched: true,
          body: true,
          code: 200
        }
      )
      result = ValidateListingPresence.call(json)
      expect(result.success?).to be_true
    end

    it "returns false if the page was not found" do
      json = Hashie::Mash.new(
        object: { seller_domain: "www.retailer.com" },
        page: {
          fetched: false,
          body: false,
          code: 404
        }
      )
      result = ValidateListingPresence.call(json)
      expect(result.success?).to be_false
    end

    it "returns false if the listing was not found" do
      json = Hashie::Mash.new(
        object: {
          seller_domain: "www.retailer.com",
          not_found: true
        },
        page: {
          fetched: true,
          body: true,
          code: 200
        }
      )
      result = ValidateListingPresence.call(json)
      expect(result.success?).to be_false
    end
  end
end
