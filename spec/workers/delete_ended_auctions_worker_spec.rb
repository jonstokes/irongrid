require 'spec_helper'

describe DeleteEndedAuctionsWorker do
  it "deletes all ended auctions" do
    site = create_site_from_repo "www.gunbroker.com"
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    2. times { auctions << FactoryGirl.create(:auction_listing, :ended) }
    DeleteEndedAuctionsWorker.new.perform(auctions)
    expect(AuctionListing.all.count).to eq(5)
    expect(Listing.find listing.id).to be_nil
  end
end
