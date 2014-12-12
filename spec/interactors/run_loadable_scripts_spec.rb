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
          }
        ),
        product: IronBase::Product.new(number_of_rounds: 10, category1: 'Ammunition'),
        listing_json: Hashie::Mash.new
      }
      result = WriteListingToIndex::RunLoadableScripts.call(opts)
      expect(result.listing.shipping.cost).to eq(995)
    end
  end
end
