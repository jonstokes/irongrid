require 'spec_helper'

describe CDN do
  before :each do
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
        "image"               => CDN::DEFAULT_IMAGE_URL,
        "image_source"        => SPEC_IMAGE_1,
        "image_download_attempted" => false,
        "item_location"       => geo_data.key,
        "seller_domain"       => "www.rspec.com",
        "seller_name"         => "rspec",
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
    CDN.clear!
  end

  after :each do
    CDN.clear!
  end

  describe "#upload_image" do
    it "should upload a new https image to S3 for a new listing with a new image" do
      image = CDN.upload_image(@listing_attrs['item_data']['image_source'])
      image.should == "https://s3.amazonaws.com/scoperrific-index-test/75f7a54c58bc2e392b56f46897ad2e68.png"
      CDN.has_image?(@listing_attrs['item_data']['image_source']).should be_true
      CDN.image_width(image).should == 200
      CDN.count.should == 1
    end

    it "should upload a new http image to S3 for a new listing with a new image" do
      @listing_attrs['item_data']['image_source'].sub!("https","http")
      image = CDN.upload_image(@listing_attrs['item_data']['image_source'].sub("https","http"))
      image.should == "https://s3.amazonaws.com/scoperrific-index-test/9d5e27121cc8ee8bd8c8347b4b8909a7.png"
      CDN.has_image?(@listing_attrs['item_data']['image_source']).should be_true
      CDN.image_width(image).should == 200
      CDN.count.should == 1
    end

    it "should return default image url if the page's image is nil" do
      CDN.upload_image(nil).should == CDN::DEFAULT_IMAGE_URL
      CDN.count.should be_zero
    end

    it "should return default image url if the page's image is not found" do
      CDN.upload_image("http://scoperrific.com/bogus_image.jpg").should == CDN::DEFAULT_IMAGE_URL
      CDN.count.should be_zero
    end

    it "should return the CDN url if that image already exists on S3" do
      image = CDN.upload_image(@listing_attrs['item_data']['image_source'])
      new_attrs = @listing_attrs.merge(:digest => "bbbb", :url => "http://rspec.com/bazqux") 
      CDN.upload_image(new_attrs['item_data']['image_source']).should == image
      CDN.count.should == 1
    end

    it "should return the default image url if the image is actually an HTML response" do
      CDN.upload_image(SPEC_ERROR_IMAGE).should == CDN::DEFAULT_IMAGE_URL
      CDN.count.should be_zero
    end
  end
end
