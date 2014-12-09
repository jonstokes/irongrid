require 'spec_helper'

describe WriteListingToIndex::FindOrCreateListing do
  describe '#call' do
    it 'retrieves a listing object for a listing that already exists in the index' do
      listing = create(:listing)
      listing_json = Hashie::Mash.new(ObjectMapper.json_from_listing(listing))
      page = Hashie::Mash.new(
          code: 200,
          url: listing.url.page
      )
      IronBase::Listing.refresh_index
      listing2 = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          page:         page,
          url:          listing.url
      ).listing
      expect(listing2.persisted?).to eq(true)
      expect(IronBase::Listing.count).to eq(1)
      expect(IronBase::Listing.find(listing2.id).id).to eq(listing.id)
    end

    it 'returns a new, unsaved listing object when a listing with this id does not exist in the index' do
      listing_json = Hashie::Mash.new(
          title: 'New Listing'
      )
      page = Hashie::Mash.new(
          code: 200,
          url: 'http://www.retailer.com/1'
      )
      IronBase::Listing.refresh_index
      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          url: Hashie::Mash.new(page: page.url, purchase: page.url),
          page: page
      ).listing
      expect(listing.persisted?).to eq(false)
      expect(IronBase::Listing.count).to eq(0)
      expect(IronBase::Listing.find(listing.id)).to be_nil
    end
  end

  describe '#listing_id' do
    it 'should use the purchase url when there is no id tag' do
      listing_json = Hashie::Mash.new(title: 'New Listing')
      page_url = 'http://www.retailer.com'
      purchase_url = "#{page_url}-buy"
      page = Hashie::Mash.new(
          code: 200,
          url: page_url
      )
      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          url: Hashie::Mash.new(page: page_url, purchase: purchase_url),
          page: page
      ).listing
      expect(listing.id).to eq(Digest::MD5.hexdigest(purchase_url))
    end

    it 'should use an id tagged url when there is an id tag in the listing json' do
      id_tag = '-123'
      listing_json = Hashie::Mash.new(
          title: 'New Listing',
          id: id_tag
      )
      page_url = 'http://www.retailer.com'
      purchase_url = "#{page_url}-buy"
      page = Hashie::Mash.new(
          code: 200,
          url: page_url
      )
      listing = WriteListingToIndex::FindOrCreateListing.call(
          listing_json: listing_json,
          url: Hashie::Mash.new(page: page_url, purchase: purchase_url),
          page: page
      ).listing
      expect(listing.id).to eq(Digest::MD5.hexdigest("#{purchase_url}!#{id_tag}"))
    end
  end
end