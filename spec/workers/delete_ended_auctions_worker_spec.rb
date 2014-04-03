require 'spec_helper'

describe DeleteEndedAuctionsWorker do
  it "deletes all ended auctions" do
    site = create_site_from_repo "www.gunbroker.com"
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    2.times { auctions << FactoryGirl.create(:auction_listing, :ended) }
    DeleteEndedAuctionsWorker.new.perform(auctions)
    expect(AuctionListing.all.count).to eq(5)
    expect {
      Listing.find auctions.first.id
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect {
      Listing.find auctions.last.id
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "does not fail when it encounters a listing that has already been deleted" do
    site = create_site_from_repo "www.gunbroker.com"
    5.times { FactoryGirl.create(:auction_listing) }
    auctions = []
    2.times { auctions << FactoryGirl.create(:auction_listing, :ended) }
    DeleteEndedAuctionsWorker.new.perform(auctions)
    expect(AuctionListing.all.count).to eq(5)
    expect {
      Listing.find auctions.first.id
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect {
      Listing.find auctions.last.id
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect {
      DeleteEndedAuctionsWorker.new.perform(auctions)
    }.not_to raise_error
  end

end
