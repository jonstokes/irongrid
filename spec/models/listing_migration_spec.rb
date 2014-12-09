require 'spec_helper'

describe ListingMigration do

  describe 'write_listing_to_index' do
    it 'writes a listing to the index in the new ES format' do
      pending "Example"
    end
  end

  describe 'verify' do
    it 'verifies the url format of the new listing' do
      pending 'Example'
    end
  end

  describe 'fix_listing_metadata' do
    it 'fixes the caliber_category for a listing when necessary' do
      pending 'Example'
    end

    it 'Only returns a hard-categorized category' do
      pending 'Example'
    end

    it 'copies over the timestamps for a listing' do
      pending 'Example'
    end
  end

  describe 'json' do
    it 'formats a listing as stretched_json' do
      pending "Example"
    end
  end

  describe 'page_url' do
    it 'gives the feed url for a feed listing' do
      pending "Example"
    end

    it 'gives the bare_url for a non-feed listing' do
      pending "Example"
    end
  end

  describe 'listing_url' do
    it 'gives the bare_url for a feed listing' do
      pending "EXample"
    end

    it 'gives nil for a non-feed listing' do
      pending "Example"
    end
  end
end