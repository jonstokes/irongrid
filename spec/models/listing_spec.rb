# == Schema Information
#
# Table name: listings
#
#  id                     :integer          not null, primary key
#  title                  :text             not null
#  description            :text
#  keywords               :text
#  digest                 :string(255)      not null
#  type                   :string(255)      not null
#  seller_domain          :string(255)      not null
#  seller_name            :string(255)      not null
#  url                    :text             not null
#  category1              :string(255)
#  category2              :string(255)
#  item_condition         :string(255)
#  image                  :string(255)      not null
#  stock_status           :string(255)
#  item_location          :string(255)
#  price_in_cents         :integer
#  sale_price_in_cents    :integer
#  buy_now_price_in_cents :integer
#  current_bid_in_cents   :integer
#  minimum_bid_in_cents   :integer
#  reserve_in_cents       :integer
#  auction_ends           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  price_on_request       :string(255)
#  engine                 :string(255)
#  inactive               :boolean
#  update_count           :integer
#  geo_data_id            :integer
#  category_data          :hstore
#

require 'spec_helper'

describe Listing do
  before :all do
    CDN.clear!
  end

  before :each do
    @site = create_site_from_repo "www.retailer.com"
    @geo_data = FactoryGirl.create(:geo_data)
    @listing_attrs =  {
      "url"                   => "http://rspec.com/bogus_url.html",
      "digest"                => "aaaa",
      "type"                  => "RetailListing",
      "item_data" => {
        "title"               => [
          {"title" => "Foo"},
          {"scrubbed" => "bar"},
          {"normalized" => "qux"},
          {"autocomplete" => "baz"}
        ],
        "description"         => "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut.",
        "keywords"            => "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut.",
        "image"               => SPEC_IMAGE_1,
        "item_location"       => @geo_data.key,
        "seller_domain"       => @site.domain,
        "seller_name"         => @site.name,
        "category1" => [
          { "category1"  => "guns" },
          { "classification_type"  => "hard" },
          { "score"  => "1" }
        ],
        "item_condition"      => "New",
        "availability"        => "in_stock",
        "price_in_cents"      => 1099,
        "sale_price_in_cents" => 999
      }
    }
    @listing_attrs["item_data"].merge!(@geo_data.to_h)

    @page = double()
    @listing_attrs.each do |k, v| 
      @page.stub(k) { v }
    end
    @page.stub("listing") { @listing_attrs }
    CDN.clear!
  end

  after :each do
    CDN.clear!
  end

  describe "#create" do
    it "should create a new listing in the db and index" do
      Listing.create(@listing_attrs)
      listing = Listing.last
      listing.seller_domain.should == @site.domain
      listing.seller_name.should == @site.name
      listing.price_in_cents.should == 1099
      listing.availability.should == "in_stock"
      listing.latitude.should == "34.9457089"
      listing.longitude.should == "-82.9716617"
      listing.state_code.should == "SC"
      listing.country_code.should == "US"
      listing.postal_code.should == "29676"
      Listing.index.retrieve("retail_listing", Listing.last.id).should_not be_nil
    end
  end

  describe "#dirty!" do
    it "dirties a listing by incrementing its update_count" do
      listing = FactoryGirl.create(:retail_listing)
      updated_at = listing.updated_at
      sleep 1
      listing.dirty!
      expect(Listing.first.update_count).to eq(1)
      expect(Listing.first.updated_at).to be > updated_at
    end
  end

  describe "#to_indexed_json" do
    it "generates JSON for storage in the ES index" do
      listing = Listing.create(@listing_attrs)
      Listing.index.refresh
      item = Listing.index.retrieve("retail_listing", listing.id)
      item.type.should == "retail_listing"
      item.url.should == "http://rspec.com/bogus_url.html"
      item.digest.should == "aaaa"
      item.seller_domain.should == @site.domain
      item.seller_name.should == @site.name
      item.title.first.title.should == "Foo"
      item.image.should == SPEC_IMAGE_1
      item.description.should == "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut."
      item.keywords.should == "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut."
      item.price_in_cents.should == 1099
      item.sale_price_in_cents.should == 999
      item.item_condition.should == "New"
      item.availability.should == "in_stock"
      item.latitude.should == "34.9457089"
      item.longitude.should == "-82.9716617"
      item.coordinates.should == "34.9457089,-82.9716617"
      item.state_code.should == "SC"
      item.country_code.should == "US"
      item.postal_code.should == "29676"
    end
  end

  describe "#deactivate!" do
    it "should deactivate a listing and remove it from the index" do
      Listing.create(@listing_attrs)
      Listing.last.deactivate!
      Listing.last.should_not be_active
      Listing.index.retrieve("retail_listing", Listing.last.id).should be_nil
    end
  end

  describe "#destroy" do
    it "should delete the listing from the db and index" do
      Listing.create(@listing_attrs)
      listing = Listing.last
      listing.destroy
      Listing.count.should == 0
      CDN.count.should == 0
      Listing.index.retrieve("retail_listing", listing.id).should be_nil
    end
  end
end
