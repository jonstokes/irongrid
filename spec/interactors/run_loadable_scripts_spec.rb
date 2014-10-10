require 'spec_helper'

describe RunLoadableScripts do
  before :each do
    @site = create_site "www.budsgunshop.com"
    @site.load_scripts
  end

  describe "#perform" do
    it "runs the scripts in a site's scripts manifest" do
      opts = {
        site: @site,
        current_price_in_cents: 1000,
        discount_in_cents: 10,
        number_of_rounds: 10,
        category1: "Guns"
      }
      result = RunLoadableScripts.perform(opts)

      puts "#{result.to_yaml}"
      expect(result.price_per_round_in_cents).to eq(100)
    end
  end
end
