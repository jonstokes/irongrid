require 'spec_helper'

describe DetermineListingType do
  it "returns the listing type based on raw_listing" do
    site = create_site("www.retailer.com")
    raw_listing = { 'listing_type' => 'Classified' }
    opts = {
      adapter: site.page_adapter,
      raw_listing: raw_listing
    }

    result = DetermineListingType.perform(opts)
    expect(result.type).to eq("ClassifiedListing")
  end

  it "returns the listing type based on defaults" do
    site = create_site("www.retailer.com")
    raw_listing = {}
    opts = {
      adapter: site.page_adapter,
      raw_listing: raw_listing
    }

    result = DetermineListingType.perform(opts)
    expect(result.type).to eq("RetailListing")
  end
end
