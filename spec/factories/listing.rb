def retail_item_data
  {
    "title" => [{"title" => "title"}],
    "availability" => "in_stock",
    "image" => "http://scoperrific.com/bogus_image.png",
    "category1" => [{"category1" => "Guns"}, {"category1_type" => "hard" }],
    "price_in_cents" => 1999,
    "sale_price_in_cents" => 1999,
    "item_condition" => "New"
  }
end

def auction_item_data
  data = retail_item_data.merge(
    "buy_now_price_in_cents" => 1999,
    "minimum_bid_in_cents" => 1999,
    "current_bid_in_cents" => 1999,
    "reserve_in_cents" => 1999,
    "auction_ends" => 10.days.from_now)

  data.reject { |k| ["price_in_cents", "sale_price_in_cents"].include? k }
end

def classified_item_data
  retail_item_data
end

FactoryGirl.define do
  factory :listing do
    sequence(:url) { |i| "http://www.retailer.com/#{i}" }
    sequence(:digest) { |i| "digest-#{i}" }
    item_data { retail_item_data.merge("seller_domain" => URI.parse(url).host) }
    updated_at Time.current
    created_at Time.current

    geo_data

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
      item_data { retail_item_data.merge("image" => "http://assets.scoperrific.com/no-image-200x140.png") }
    end

    factory :auction_listing do
      initialize_with do
        AuctionListing.new
      end

      type "AuctionListing"
      item_data { auction_item_data.merge("seller_domain" => URI.parse(url).host) }

      trait :ended do
        item_data { auction_item_data.merge("auction_ends" => 1.day.ago) }
      end
    end

    factory :classified_listing do
      initialize_with do
        ClassifiedListing.new
      end

      type "ClassifiedListing"
      item_data { classified_item_data.merge("seller_domain" => URI.parse(url).host) }
    end

    factory :retail_listing do
      initialize_with do
        RetailListing.new
      end

      type "RetailListing"
      item_data { retail_item_data.merge("seller_domain" => URI.parse(url).host) }
    end
  end
end
