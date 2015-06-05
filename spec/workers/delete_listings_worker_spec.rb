require 'spec_helper'

def auction_count
  IronBase::Listing.count do |search|
    search.filters = { listing_type: ['AuctionListing'] }
  end
end

describe DeleteListingsWorker do
  it 'deletes all ended auctions' do
    site = create_site "www.gunbroker.com"
    5.times { FactoryGirl.create(:listing, :auction) }
    auctions = []
    2.times { auctions << FactoryGirl.create(:listing, :ended_auction) }
    IronBase::Listing.refresh_index
    DeleteListingsWorker.new.perform(auctions.map(&:id))
    IronBase::Listing.refresh_index
    expect(
        IronBase::Listing.find(auctions.first.id).hits
    ).to be_empty
    expect(
        IronBase::Listing.find(auctions.last.id).hits
    ).to be_empty
    expect(auction_count).to eq(5)
  end

  it 'does not fail when it encounters a listing that has already been deleted' do
    site = create_site "www.gunbroker.com"
    5.times { FactoryGirl.create(:listing, :auction) }
    auctions = []
    2.times { auctions << FactoryGirl.create(:listing, :ended_auction) }
    IronBase::Listing.refresh_index
    DeleteListingsWorker.new.perform(auctions.map(&:id))
    IronBase::Listing.refresh_index
    expect(
      IronBase::Listing.find(auctions.first.id).hits
    ).to be_empty
    expect(
      IronBase::Listing.find(auctions.last.id).hits
    ).to be_empty
    expect(auction_count).to eq(5)
    expect {
      DeleteListingsWorker.new.perform(auctions.map(&:id))
    }.not_to raise_error
  end

end
