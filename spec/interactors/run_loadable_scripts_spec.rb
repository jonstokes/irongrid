require 'spec_helper'

describe WriteListingToIndex::RunLoadableScripts do
  before :each do
    @site = create_site 'www.budsgunshop.com'
    load_scripts
  end

  describe '#call' do
    it "runs the scripts in a site's scripts manifest" do
      opts = {
        site: @site,
        listing: IronBase::Listing.new(
          price: {
              current: 1000,
              sale: 1000,
              list: 1100
          },
          product: {
              number_of_rounds: 10,
              category1: 'Ammunition'
          },
          discount: {
              in_cents: 100,
              percent: 10
          }
        ),
        listing_json: Hashie::Mash.new
      }
      result = WriteListingToIndex::RunLoadableScripts.call(opts)
      expect(result.listing.shipping.cost).to eq(995)
    end
  end

  describe 'Price per round calculations' do
    it 'calculates the current price per round' do
      listing = IronBase::Listing.new(
          product: {
              category1: 'Ammunition',
              number_of_rounds: 10
          },
          price: {
             current: 100,
             sale: 100
          }
      )
      result = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          listing_json: Hashie::Mash.new,
          site: @site
      )
      expect(result.listing.price.per_round).to eq(10)
    end

    it 'does not overwrite PPR if it is already present' do
      listing = IronBase::Listing.new(
          product: {
              category1: 'Ammunition',
              number_of_rounds: 10
          },
          price: {
              current: 100,
              per_round: 500
          }
      )
      result = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          listing_json: Hashie::Mash.new,
          site: @site
      )
      expect(result.listing.price.per_round).to eq(500)
    end
  end

  describe 'Shipping calculations', no_es: true do
    before :each do
      @site = create_site 'www.budsgunshop.com'
      load_scripts
    end

    it 'sets the shipping cost using a script' do
      listing = IronBase::Listing.new(
          price: { current: 100 },
          product: { category1: 'Guns' },
      )
      results = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping.cost).to eq(0)
      expect(results.listing.with_shipping.price.current).to eq(100)
      expect(results.listing.with_shipping.discount).to be_nil

      listing = IronBase::Listing.new(
          price: { current: 100 },
          product: {
              category1: 'Ammunition',
              number_of_rounds: 100
          }
      )
      results = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping.cost).to eq(995)
      expect(results.listing.with_shipping.price.current).to eq(1095)
      expect(results.listing.with_shipping.price.per_round).to eq(11)

      listing = IronBase::Listing.new(
          product: { category1: 'Optics' },
      )
      results = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping.cost).to be_nil
      expect(results.listing.with_shipping).to be_nil
    end

    it 'does not blow up if the shipping makes the discount to be zero' do
      listing = IronBase::Listing.new(
          product: {
              category1: 'Ammunition',
              number_of_rounds: 100
          },
          price: {
              current: 90,
              sale: 90,
              list: 100
          },
          discount: {
              in_cents: 10,
              percent: 10
          },
          shipping: { cost: 10 }
      )
      results = WriteListingToIndex::RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.with_shipping.discount.in_cents).to eq(0)
      expect(results.listing.with_shipping.discount.percent).to eq(0)
      expect(results.listing.with_shipping.discount.ppr_percent).to eq(0)

    end

  end
end
