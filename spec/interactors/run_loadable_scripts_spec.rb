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
end
