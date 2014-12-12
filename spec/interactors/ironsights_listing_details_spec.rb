require 'spec_helper'

describe WriteListingToIndex::IronsightsListingDetails do

  describe 'call' do
    it 'calculates a discount if the listing has no list price but the product has an msrp' do
      listing = build(:listing)
      listing.price.list = nil
      listing.discount = nil
      product = IronBase::Product.new(msrp: 5999)

      result = WriteListingToIndex::IronsightsListingDetails.call(
          listing: listing,
          product: product
      )

      expect(result.listing.discount.in_cents).to eq(4000)
    end
  end
end
