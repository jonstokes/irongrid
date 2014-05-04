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
    @site = create_site "www.retailer.com"
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

  describe "#url" do
    it "returns the untagged url for a site without a link tag" do
      Listing.create(@listing_attrs)
      listing = Listing.last
      expect(listing.url).to eq(@listing_attrs["url"])
    end

    it "returns the tagged url for a site with a link tag" do
      site = Site.new(domain: "www.luckygunner.com", source: :fixture)
      site.send(:write_to_redis)
      item_data = @listing_attrs['item_data'].merge!(
        'seller_name' => site.name,
        'seller_domain' => site.domain,
        'affiliate_link_tag' => site.affiliate_link_tag
      )
      attrs = @listing_attrs.merge!(
        'url' => "http://#{site.domain}/product",
        'item_data' => item_data
      )
      tagged_url = "#{attrs['url']}#{site.affiliate_link_tag}"

      Listing.create(attrs)
      Listing.index.refresh
      listing = Listing.last
      expect(listing.url).to eq(tagged_url)

      # Also make sure that the listing's url is properly represented
      # in both the db and search index
      expect(Listing.find_by_url(attrs['url'])).not_to be_nil
      item = Listing.index.retrieve('retail_listing', listing.id)
      expect(item.url).to eq(tagged_url)
    end
  end

  describe "#update_and_dirty!" do
    it "increments a listings update_count as part of an update" do
      listing = Listing.create(@listing_attrs)
      attrs = @listing_attrs.merge("digest" => "bbbb")
      listing.update_and_dirty!(attrs)
      listing = Listing.last
      expect(listing.digest).to eq("bbbb")
      expect(listing.update_count).to eq(1)
    end

    it "does not overwrite existing hard-classified page attributes with metadata- or soft-classified updates" do
      attrs = @listing_attrs.dup
      attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".22LR", "classification_type" => "hard"]
      )
      listing = Listing.create(attrs)
      new_attrs = @listing_attrs.dup
      new_attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".17WMR", "classification_type" => "soft"]
      )
      listing = Listing.first
      listing.update_and_dirty!(new_attrs)
      expect(listing.item_data["caliber"]).to eq(["caliber" => ".22LR", "classification_type" => "hard"])
    end

    it "overwrites existing hard-classified page attributes with hard-classified updates" do
      attrs = @listing_attrs.dup
      attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".22LR", "classification_type" => "hard"]
      )
      listing = Listing.create(attrs)
      new_attrs = @listing_attrs.dup
      new_attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".17WMR", "classification_type" => "hard"]
      )
      listing = Listing.first
      listing.update_and_dirty!(new_attrs)
      expect(listing.item_data["caliber"]).to eq(["caliber" => ".17WMR", "classification_type" => "hard"])
    end

    it "overwrites existing metadata-classified page attributes with hard-classified updates" do
      attrs = @listing_attrs.dup
      attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".22LR", "classification_type" => "metadata"]
      )
      listing = Listing.create(attrs)
      new_attrs = @listing_attrs.dup
      new_attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".17WMR", "classification_type" => "hard"]
      )
      listing = Listing.first
      listing.update_and_dirty!(new_attrs)
      expect(listing.item_data["caliber"]).to eq(["caliber" => ".17WMR", "classification_type" => "hard"])
    end

    it "overwrites existing soft-classified page attributes with metadata-classified updates" do
      attrs = @listing_attrs.dup
      attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".22LR", "classification_type" => "soft"]
      )
      listing = Listing.create(attrs)
      new_attrs = @listing_attrs.dup
      new_attrs['item_data'].merge!(
         "caliber" => ["caliber" => ".17WMR", "classification_type" => "metadata"]
      )
      listing = Listing.first
      listing.update_and_dirty!(new_attrs)
      expect(listing.item_data["caliber"]).to eq(["caliber" => ".17WMR", "classification_type" => "metadata"])
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

  describe "#notify_on_match" do
    it "adds the listings id to the proper search alert queue on a percolator match" do
      query_json = '{"query":{"query_string":{"query":"Foo"}}}'
      Listing.register_percolator('abcd', query_json)

      SearchAlertQueues.should_receive(:push) do |opts|
        expect(opts[:percolator_name]).to eq('abcd')
        expect(opts[:listing_id]).to be_a(Integer)
      end

      Listing.create(@listing_attrs)
    end

    it "does not notify for listings that are just dirtied, but not really updated" do
      query_json = '{"query":{"query_string":{"query":"Foo"}}}'
      Listing.register_percolator('abcd', query_json)
      listing = Listing.create(@listing_attrs)

      SearchAlertQueues.should_not_receive(:push) do |opts|
        expect(opts[:percolator_name]).to eq('abcd')
        expect(opts[:listing_id]).to be_a(Integer)
      end

      listing.dirty!
    end

    it "does not notify for listings that are destroyed" do
      query_json = '{"query":{"query_string":{"query":"Foo"}}}'
      Listing.register_percolator('abcd', query_json)
      listing = Listing.create(@listing_attrs)

      SearchAlertQueues.should_not_receive(:push) do |opts|
        expect(opts[:percolator_name]).to eq('abcd')
        expect(opts[:listing_id]).to be_a(Integer)
      end

      listing.destroy
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
