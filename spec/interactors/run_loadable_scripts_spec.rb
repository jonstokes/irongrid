require 'spec_helper'

describe RunLoadableScripts do
  before :each do
    @site = create_site 'www.budsgunshop.com'
    load_scripts
  end

  describe '#call' do
    it "runs the scripts in a site's scripts manifest" do
      opts = {
        site: @site,
        listing: IronBase::Listing.new(
          price: { current: 1000 },
          product: {
              number_of_rounds: 10,
              category1: 'Ammunition'
          },
          discount: { in_cents: 10 },
        )
      }
      result = RunLoadableScripts.call(opts)
      expect(result.listing.shipping_cost).to eq(995)
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
             current: 100
          }
      )
      result = RunLoadableScripts.call(
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
      result = RunLoadableScripts.call(
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
          product: { category1: 'Guns' },
      )
      results = RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping_cost).to eq(0)

      listing = IronBase::Listing.new(
          product: { category1: 'Ammunition' },
      )
      results = RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping_cost).to eq(995)

      listing = IronBase::Listing.new(
          product: { category1: 'Optics' },
      )
      results = RunLoadableScripts.call(
          listing: listing,
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.listing.shipping_cost).to be_nil
    end
  end
end
