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
      load_scripts
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

      it 'calculates the price per round with shipping' do
        listing = build(:listing)
        listing.with_shipping = nil
        product = IronBase::Product.new(
            category1: 'Ammunition',
            number_of_rounds: 10
        )

        result = WriteListingToIndex::RunLoadableScripts.call(
            listing: listing,
            product: product,
            site:    @site
        )

        expect(result.listing.with_shipping.price.per_round).to eq(210)
      end

      it 'calculates the discount with shipping' do
        listing = build(:listing)
        listing.with_shipping = nil
        listing.discount = nil
        listing.price.current = listing.price.sale = 700

        product = IronBase::Product.new(
            category1: 'Ammunition',
            number_of_rounds: 10
        )

        listing = WriteListingToIndex::RunLoadableScripts.call(
            listing: listing,
            product: product,
            site:    @site
        ).listing

        expect(listing.discount.in_cents).to eq(1299)
        expect(listing.discount.percent).to eq(65)
        expect(listing.shipping.cost).to eq(995)
        expect(listing.with_shipping.discount.in_cents).to eq(1199)
        expect(listing.with_shipping.discount.percent).to eq(60)
      end

    end

  end
end
