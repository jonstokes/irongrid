require 'spec_helper'

describe Shipping::SetShippingCost do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.budsgunshop.com"
      Script.create_from_file("#{Rails.root}/spec/fixtures/scripts/www--budsgunshop--com.rb")
    end

    it "sets the shipping cost using the listing_json" do
      results = Shipping::SetShippingCost.perform(
        product_category1: "Guns",
        site: @site,
        listing_json: Hashie::Mash.new(shipping_cost_in_cents: 200)
      )
      expect(results.shipping_cost_in_cents).to eq(200)
    end

    it "sets the shipping cost using a script" do
      results = Shipping::SetShippingCost.perform(
        product_category1: "Guns",
        site: @site,
        listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to eq(0)

      results = Shipping::SetShippingCost.perform(
        product_category1: "Ammunition",
        site: @site,
        listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to eq(995)

      results = Shipping::SetShippingCost.perform(
        product_category1: "Optics",
        site: @site,
        listing_json: Hashie::Mash.new
      )
      expect(results.shipping_cost_in_cents).to be_nil
    end

  end
end
