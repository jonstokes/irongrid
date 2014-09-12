require 'spec_helper'

describe Shipping::SetShippingCost do
  describe "#perform", no_es: true do
    before :each do
      @site = create_site "www.budsgunshop.com"
    end

    it "sets the shipping cost using the listing_json" do
      results = Shipping::SetShippingCost.perform(
        product_category1: "Guns",
        site: @site,
        listing_json: Hashie::Mash.new(shipping_cost_in_cents: 200)
      )
      expect(results.shipping_cost_in_cents).to eq(200)
    end
  end
end
