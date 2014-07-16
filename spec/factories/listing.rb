def retail_item_data
  {
    "title"               => [{"title" => "title"}],
    "availability"        => "in_stock",
    "image_source"        => "http://www.retailer.com/images/1.png",
    "image_download_attempted" => true,
    "category1"           => [{"category1" => "Guns"}, {"category1_type" => "hard" }],
    "price_in_cents"      => 1999,
    "sale_price_in_cents" => 1999,
    "item_condition"      => "New"
  }
end

def auction_item_data
  retail_item_data.merge(
    "buy_now_price_in_cents" => 1999,
    "minimum_bid_in_cents"   => 1999,
    "current_bid_in_cents"   => 1999,
    "reserve_in_cents"       => 1999,
  ).reject { |k| ["price_in_cents", "sale_price_in_cents"].include? k }
end

def classified_item_data
  retail_item_data
end

FactoryGirl.define do
  factory :listing do
    sequence(:url) { |i| "http://www.retailer.com/#{i}" }
    sequence(:digest) { |i| "digest-#{i}" }
    image { "http://scoperrific.com/bogus_image.png" }
    item_data { retail_item_data.merge("seller_domain" => URI.parse(url).host) }
    updated_at Time.current
    created_at Time.current

    trait :optics do
      item_data { retail_item_data.merge("category1" => [{"category1" => "Optics"}, {"category1_type" => "hard" }]) }
    end

    trait :ammo do
      item_data { retail_item_data.merge("category1" => [{"category1" => "Ammunition"}, {"category1_type" => "hard" }]) }
    end

    trait :firearm do
      item_data { retail_item_data.merge("category1" => [{"category1" => "Guns"}, {"category1_type" => "hard" }]) }
    end

    trait :price_on_request do
      item_data { retail_item_data.merge("price_on_request" => true) }
    end

    trait :out_of_stock do
      item_data { retail_item_data.merge("availability" => "out_of_stock") }
    end

    trait :in_stock do
      item_data { retail_item_data.merge("availability" => "in_stock") }
    end

    trait :inactive do
      inactive true
    end

    trait :no_image do
      image CDN::DEFAULT_IMAGE_URL
      image_download_attempted { false }
      item_data {
        retail_item_data.merge("image_source" => SPEC_IMAGE_1)
      }
    end

    trait :stale do
      updated_at 10.days.ago
    end

    factory :auction_listing do
      initialize_with do
        AuctionListing.new
      end

      type "AuctionListing"
      auction_ends 10.days.from_now
      seller_domain { URI.parse(url).host }

      trait :ended do
        auction_ends 10.days.ago
      end
    end

    factory :classified_listing do
      initialize_with do
        ClassifiedListing.new
      end

      type "ClassifiedListing"
      seller_domain { URI.parse(url).host }
    end

    factory :retail_listing do
      initialize_with do
        RetailListing.new
      end

      type "RetailListing"
      seller_domain { URI.parse(url).host }
    end
  end
end
