FactoryGirl.define do
  factory :listing, class: IronBase::Listing do

    to_create do |listing|
      listing.send(:run_validations)
      listing.persist!
      listing.send(:notify_on_match)
    end

    ignore do
      domain { 'www.retailer.com' }
      base_url { "http://#{domain}/" }
    end

    sequence(:id)     { |n| "#{base_url}#{n}"}
    sequence(:title)  { |n| "Listing Title - #{n}" }
    sequence(:url) do |n|
      { page: "#{base_url}#{n}", purchase: "#{base_url}#{n}" }
    end
    sequence(:digest) { |n| "digest-#{n}" }
    engine            { 'ironsights' }
    image do
      {
          source: "http://scoperrific.com/bogus_image.png",
          cdn: nil
      }
    end
    with_shipping {
      {
          price: {
              current: 165,
              sale:    165
          },
          discount: {
              in_cents: 0,
              percent: 0
          }
      }
    }
    price do
      {
          current: 1999,
          buy_now: 1999,
          list:    1999,
          sale:    1999
      }
    end
    discount do
      {
          in_cents: 50,
          percent:  10.5
      }
    end
    seller do
      {
          site_name: 'Retailer',
          domain:     domain
      }
    end
    product do
      {
          category1: 'Guns'
      }
    end
    created_at { 2.days.ago.utc }
    updated_at { Time.now.utc }
  end

  trait :optics do
    product do
      { category1: 'Optics' }
    end
  end

  trait :ammo do
    product do
      { category1: 'Ammunition' }
    end
  end

  trait :firearm do
    product do
      { category1: 'Guns' }
    end
  end


  trait :price_on_request do
    price do
      {
          on_request:    true
      }
    end
  end

  trait :out_of_stock do
    availability { 'out_of_stock' }
  end

  trait :in_stock do
    availability { 'in_stock' }
  end

  trait :inactive do
    inactive true
  end

  trait :no_image do
    image do
      {
          cdn: CDN::DEFAULT_IMAGE_URL,
          source: SPEC_IMAGE_1,
          download_attempted: false
      }
    end
  end

  trait :stale do
    updated_at { 10.days.ago }
  end

  trait :auction do
    type 'AuctionListing'
    auction_ends 10.days.from_now
  end

  trait :ended_auction do
    type 'AuctionListing'
    auction_ends 2.days.ago
  end

  trait :classified do
    type "ClassifiedListing"
  end

  trait :retail do
    type "RetailListing"
  end
end
