require 'spec_helper'

describe WriteListingWorker do

  # The desired behaviors for the following scenarios are broken out
  # in a table here: http://goo.gl/20W6DF

  before :each do
    @site = create_site "www.retailer.com"
    @geo_data = FactoryGirl.create(:geo_data)
    @redirect_url = "http://www.retailer.com/new-listing-location"
    @not_found_redirect = "http://www.retailer.com/"

    @listing_data =  {
      url:                    nil,
      digest:                 "aaaa",
      type:                   "RetailListing",
      seller_domain:          @site.domain,
      image:                  'http://cdn.ironsights.com/1235.jpg',
      title:                  'Foo',
      description:            Faker::Lorem.paragraph,
      keywords:               Faker::Lorem.sentence,
      image:                  "http://www.retailer.com/img.jpg",
      "item_location"       => @geo_data.key,
      "seller_name"         => @site.name,
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
    @page = {
      code: 200,
    }
  end
end
