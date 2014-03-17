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
    pending "Needs refactor of create_with_cdn"
    site = create_site_from_repo "www.armslist.com"
    geo_data = FactoryGirl.create(:geo_data)
    @listing_attrs =  {
      "url"                   => "http://rspec.com/bogus_url.html",
      "digest"                => "aaaa",
      "type"                  => "RetailListing",
      "geo_data_id"           => geo_data.id,
      "site_id"               => site.id,
      "item_data" => {
        "title"               => [
          {"title" => "Foo"},
          {"scrubbed" => "bar"},
          {"normalized" => "qux"},
          {"autocomplete" => "baz"}
        ],
        "description"         => Faker::Lorem.paragraph,
        "keywords"            => Faker::Lorem.sentence,
        "image"               => SPEC_IMAGE_1,
        "item_location"       => geo_data.key,
        "seller_domain"       => "www.rspec.com",
        "seller_name"         => "rspec",
        "category1" => [
          { "category1"  => "guns" },
          { "classification_type"  => "hard" },
          { "score"  => "1" }
        ],
        "item_condition"      => "New",
        "stock_status"        => "In Stock",
        "price_in_cents"      => 1099,
        "sale_price_in_cents" => 999
      }
    }
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

  describe "#latitude", no_es: true do
    it "should return the correct latitude for a new listing" do
      Listing.create_with_cdn(@listing_attrs).should == :success
      Listing.last.latitude.should == "34.9457089"
    end
  end

  describe "#longitude", no_es: true do
    it "should return the correct longitude for a new listing" do
      Listing.create_with_cdn(@listing_attrs).should == :success
      Listing.last.longitude.should == "-82.9716617"
    end
  end

  describe "#state_code", no_es: true do
    it "should return the correct state code" do
      Listing.create_with_cdn(@listing_attrs).should == :success
      Listing.last.state_code.should == "SC"
    end
  end

  describe "#country_code", no_es: true do
    it "should return the correct country code" do
      Listing.create_with_cdn(@listing_attrs).should == :success
      Listing.last.country_code.should == "US"
    end
  end

  describe "#zip_code", no_es: true do
    it "should return the correct zip code" do
      Listing.create_with_cdn(@listing_attrs).should == :success
      Listing.last.postal_code.should == "29676"
    end
  end

  describe "#deactivate!" do
    it "should deactivate a listing and remove it from the index" do
      Listing.create_with_cdn(@listing_attrs)
      Listing.last.deactivate!
      Listing.last.should_not be_active
      Listing.index.retrieve("retail_listing", Listing.last.id).should be_nil
    end

    it "should populate a retail listing's geo_data with a site default if it was previously nil" do
      temp = @listing_attrs["item_data"]
      temp.merge!("seller_domain" => "www.impactguns.com", "item_location" => nil)
      @listing_attrs["item_data"] = temp
      Listing.create_with_cdn(@listing_attrs)
      Listing.last.deactivate!
      Listing.last.should_not be_active
      Listing.last.geo_data.should_not be_nil
    end
  end

  describe "#delete_with_cdn" do
    it "should delete the listing and the image if the image is unshared" do
      Listing.create_with_cdn(@listing_attrs)
      listing = Listing.last
      CDN.count.should == 1
      listing.delete_with_cdn
      Listing.count.should == 0
      CDN.count.should == 0
      Listing.index.retrieve("retail_listing", listing.id).should be_nil
    end

    it "should delete the listing but not the image if the image is shared" do
      Listing.create_with_cdn(@listing_attrs)
      Listing.create_with_cdn(@listing_attrs.merge("digest" => "bbbb", "url" => "http://foo.com/rspec"))
      Listing.count.should == 2
      Listing.last.delete_with_cdn
      Listing.count.should == 1
    end
  end
end
