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
    it 'should create a new listing object for a listing that does not exist in the index' do
      pending 'Example'
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