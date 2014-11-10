require 'spec_helper'

describe FindOrCreateListing do
  before :each do
    @listing_json = Hashie::Mash.new attributes_for(:listing)
    @url = @listing_json.url
    @listing_json.url = @listing_json.id = nil
    @page = Hashie::Mash.new(code: 200)
    @id_tag = 'sku-1234'
  end

  describe '#call' do
    it 'retrieves a listing object for a listing that already exists in the index' do
      listing = create(:listing)
      IronBase::Listing.refresh_index
      listing2 = FindOrCreateListing.call(listing_json: listing.data, url: listing.url).listing
      expect(listing2.persisted?).to eq(true)
      expect(IronBase::Listing.count).to eq(1)
      expect(IronBase::Listing.find(listing2.id).id).to eq(listing.id)
    end

    it 'returns a new, unsaved listing object when a listing with this id does not exist in the index' do
      listing = create(:listing)
      IronBase::Listing.refresh_index
      listing2 = FindOrCreateListing.call(
          listing_json: listing.data,
          url: listing.url.merge(purchase: "#{@url}-123")
      ).listing
      expect(listing2.persisted?).to eq(false)
      expect(IronBase::Listing.count).to eq(1)
      expect(IronBase::Listing.find(listing2.id)).to be_nil
    end
  end

  describe '#listing_id' do
    it 'should use the purchase url when there is no id tag' do
      listing = FindOrCreateListing.call(listing_json: @listing_json, url: @url).listing
      expect(listing.id).to eq(@url.purchase)
    end

    it 'should use an id tagged url when there is an id tag in the listing json' do
      listing_json = @listing_json.merge(id: @id_tag)
      listing = FindOrCreateListing.call(listing_json: listing_json, url: @url).listing
      expect(listing.id).to eq("#{@url.purchase}!#{@id_tag}")
    end
  end
end