require 'spec_helper'

describe WriteListingToIndex::RunLoadableScripts do
  before :each do
    @site = create_site 'www.budsgunshop.com'
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
          discount: {
              in_cents: 100,
              percent: 10
          },
          engine: 'ironsights'
        ),
        product: IronBase::Product.new(number_of_rounds: 10, category1: 'Ammunition'),
        listing_json: Hashie::Mash.new
      }
      result = WriteListingToIndex::RunLoadableScripts.call(opts)
      expect(result.listing.shipping.cost).to eq(995)
    end

    it 'exposes common variables to the script' do
      site = create_site 'www.midwayusa.com'
      opts = {
          site: site,
          listing: IronBase::Listing.new(
              price: {
                  current: 1000,
                  sale: 1000,
                  list: 1100
              },
              engine: 'ironsights'
          ),
          product: IronBase::Product.new(weight: { shipping: 0.5 }),
          listing_json: Hashie::Mash.new(message2: true),
      }
      result = WriteListingToIndex::RunLoadableScripts.call(opts)
      expect(result.listing.shipping.cost).to eq(899)
    end

    describe 'standard ironsights calculations' do
      it 'calculates a discount if the listing has no list price but the product has an msrp' do
        listing = build(:listing)
        listing.price.list = nil
        listing.discount = nil
        product = IronBase::Product.new(msrp: 5999)

        result = WriteListingToIndex::RunLoadableScripts.call(
            listing: listing,
            product: product,
            site:    @site
        )

        expect(result.listing.discount.in_cents).to eq(4000)
      end

      it 'calculates the price per round' do
        listing = build(:listing)
        product = IronBase::Product.new(
            category1: 'Ammunition',
            number_of_rounds: 10
        )
        result = WriteListingToIndex::RunLoadableScripts.call(
            listing: listing,
            product: product,
            site:    @site
        )

        expect(result.listing.price.per_round).to eq(200)
      end
    end
  end
end
