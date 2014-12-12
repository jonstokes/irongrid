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

    it 'calculates the price per round' do
      listing = build(:listing)
      product = IronBase::Product.new(
          category1: 'Ammunition',
          number_of_rounds: 10
      )

      result = WriteListingToIndex::IronsightsListingDetails.call(
          listing: listing,
          product: product
      )

      expect(result.listing.price.per_round).to eq(200)
    end

    it 'calculates the price per round with shipping' do
      listing = build(:listing)
      listing.with_shipping = nil
      product = IronBase::Product.new(
          category1: 'Ammunition',
          number_of_rounds: 10
      )

      result = WriteListingToIndex::IronsightsListingDetails.call(
          listing: listing,
          product: product
      )

      expect(result.listing.with_shipping.price.per_round).to eq(210)
    end

    

  end
end
