require 'spec_helper'

describe SoftCategorize do
  it "does nothing if the listing already has a hard category" do
    category1 = ElasticSearchObject.new(
      "category1",
      raw: "Optics",
      classification_type: "hard"
    )
    result = SoftCategorize.perform(
      category1: category1
    )
    expect(result.category1.raw).to eq("Optics")
    expect(result.category1.classification_type).to eq("hard")
  end

  it "metadata categorizes a listing if that's possible" do
    category1 = ElasticSearchObject.new(
      "category1",
      raw: "None",
      classification_type: "fall_through"
    )
    result = SoftCategorize.perform(
      category1: category1,
      grains: 10,
      caliber: "9mm Luger",
      number_of_rounds: 100
    )
    expect(result.category1.raw).to eq("Ammunition")
    expect(result.category1.classification_type).to eq("metadata")
  end

  it "applies a fall-through category of None" do
    pending "Example"
  end

  describe "#soft_categorize" do
    before :each do
      @site = create_site "www.retailer.com"
      @geo_data = FactoryGirl.create(:geo_data)
      @item_data = {
        "title"               => [
          {"title" => "Foo"},
          {"scrubbed" => "bar"},
          {"normalized" => "qux"},
          {"autocomplete" => "baz"}
        ],
        "description"         => "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut.",
        "keywords"            => "Molestiae pariatur sed assumenda. Accusamus nulla aut laborum voluptates aut sunt ut.",
        "image"               => SPEC_IMAGE_1,
        "image_source"        => "http://#{@site.domain}/images/1",
        "item_location"       => @geo_data.key,
        "seller_domain"       => @site.domain,
        "seller_name"         => @site.name,
        "category1" => [
          { "category1"  => "Guns" },
          { "classification_type"  => "hard" }
        ],
        "item_condition"      => "New",
        "availability"        => "in_stock",
        "price_in_cents"      => 100,
        "sale_price_in_cents" => 100
      }
      @listing_attrs =  {
        "url"       => "http://#{@site.domain}/1.html",
        "digest"    => "aaaa",
        "type"      => "RetailListing",
        "item_data" => @item_data
      }
      @listing_attrs["item_data"].merge!(@geo_data.to_h)
      @category1 = ElasticSearchObject.new(
        "category1",
        raw: "None",
        classification_type: "fall_through"
      )
    end

    it "soft categorizes a listing using only hard-classified seed data" do
      title_string = "Ruger Mini-14"
      title_json = [
        { "title"        => title_string },
        { "scrubbed"     => title_string },
        { "normalized"   => title_string },
        { "autocomplete" => title_string }
      ]
      soft_category_json = [
        { "category1"  => "Accessories" },
        { "classification_type"  => "soft" }
      ]
      title = ElasticSearchObject.new(
        "title",
        raw: title_string,
        scrubbed: title_string,
        normalized: title_string,
        autocomplete: title_string
      )
      10.times do |i|
        item_data = @item_data.merge("title" => title_json)
        listing_attrs = @listing_attrs.merge(
          "item_data" => item_data,
          "digest" => "hard#{i}",
          "url" => "http://#{@site.domain}/hard#{i}"
        )
        Listing.create(listing_attrs)
      end
      20.times do |i|
        item_data = @item_data.merge("title" => title_json, "category1" => soft_category_json)
        listing_attrs = @listing_attrs.merge(
          "item_data" => item_data,
          "digest" => "soft#{i}",
          "url" => "http://#{@site.domain}/soft#{i}"
        )
        Listing.create(listing_attrs)
      end
      Listing.index.refresh
      result = SoftCategorize.perform(
        title: title,
        category1: @category1,
        current_price_in_cents: 100
      )
      expect(result.category1.raw).to eq("Guns")
      expect(result.category1.classification_type).to eq("soft")
    end
  end


end
