FactoryGirl.define do
  factory :site do
    sequence(:name) { |i| "Seller #{i}" }
    sequence(:domain) { |i| "www.seller-#{i}.com" }
    adapter_source "---"
    engine "www.ironsights.com"
    read_with "RefreshLinksWorker"
    service_options {}
    active true
    rate_limits {}
    read_at Time.now
    commit_sha "abcdefg123"
  end

  trait :rss do
    scrape_with_service "rss"
  end

  trait :affiliates do
    scrape_with_service "affiliates"
  end

end
