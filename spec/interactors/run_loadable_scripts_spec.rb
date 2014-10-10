require 'spec_helper'

describe RunLoadableScripts do
  before :each do
    @site = create_site "www.budsgunshop.com"
    load_scripts
  end

  describe "#perform" do
    it "runs the scripts in a site's scripts manifest" do
      opts = {
        site: @site,
        current_price_in_cents: 1000,
        number_of_rounds: 10,
        discount_in_cents: 10,
        category1: "Ammunition"
      }
      result = RunLoadableScripts.perform(opts)

      expect(result.price_per_round_in_cents).to eq(100)
    end
  end
end
