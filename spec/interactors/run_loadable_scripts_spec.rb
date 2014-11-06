require 'spec_helper'

describe RunLoadableScripts do
  before :each do
    @site = create_site "www.budsgunshop.com"
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
    it "calculates the current price per round" do
      result = SetPricePerRound.perform(
          current_price_in_cents: 100,
          number_of_rounds: ElasticSearchObject.new("number_of_rounds", raw: 10),
          category1: ElasticSearchObject.new("category1", raw: "Ammunition"),
          listing_json: Hashie::Mash.new
      )
      expect(result.price_per_round_in_cents).to eq(10)
    end
  end

  describe 'Shipping calculations', no_es: true do
    before :each do
      @site = create_site "www.budsgunshop.com"
      Loadable::Script.create_from_file("#{Rails.root}/spec/fixtures/scripts/www--budsgunshop--com.rb")
    end

    it "sets the shipping cost using the listing_json" do
      results = Shipping::SetShippingCost.perform(
          category1: "Guns",
          site: @site,
          listing_json: Hashie::Mash.new(shipping_cost_in_cents: 200)
      )
      expect(results.shipping_cost_in_cents).to eq(200)
    end

    it "sets the shipping cost using a script" do
      results = Shipping::SetShippingCost.perform(
          category1: "Guns",
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to eq(0)

      results = Shipping::SetShippingCost.perform(
          category1: "Ammunition",
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to eq(995)

      results = Shipping::SetShippingCost.perform(
          category1: "Optics",
          site: @site,
          listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to be_nil
    end

  end
end
