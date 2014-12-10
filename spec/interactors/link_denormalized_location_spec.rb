require 'spec_helper'

describe WriteListingToIndex::LinkDenormalizedLocation do

  before :each do
    @location = "1213 Newning Ave., Austin TX"
    @listing_json = Hashie::Mash.new(location: @location)
    @listing = IronBase::Listing.new
    @lat = '30.25054399999999'
    @lon = '-97.74310799999999'
  end

  describe '#call' do
    it 'sets the listing location' do
      listing = WriteListingToIndex::LinkDenormalizedLocation.call(listing_json: @listing_json, listing: @listing).listing
      expect(listing.location.id).to eq(@location.upcase)
      expect(listing.location.state_code).to eq('TX')
      expect(listing.location.coordinates).to eq("#{@lat},#{@lon}")
    end
  end
end