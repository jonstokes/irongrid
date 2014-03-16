require 'digest/md5'

FactoryGirl.define do
  factory :listing_scraper do
    url "http://scoperrific.com/bogus_url.html"
    title Faker::Lorem.sentence
    description Faker::Lorem.paragraph
    keywords Faker::Lorem.sentence
    domain "www.rspec.com"
    engine "www.ironsights.com"
    seller_domain "www.rspec.com"
    seller_name "rspec"
    type "RetailListing"
    image "http://scoperrific.com/bogus_image.png"
    digest { Digest::MD5.hexdigest(Faker::Lorem.paragraph) }
    condition_new "New"
    condition_used "Used"
    out_of_stock_message "Out of Stock"
    in_stock_message "In Stock"
    doc nil
    price 1300
    price_on_request "POR"
    sale_price 1000
    buy_now_price nil
    current_bid nil
    minimum_bid nil
    reserve_in_cents 100
    auction_ends nil
    digest_attributes nil
    item_sold "Sold"
    item_location "Florida"
    category "Guns"
    category1 "guns"
    subcategory "Rimfire"
    category2 "rimfire"
    not_found nil
    seller_defaults nil
    validation nil
    exclude_from_title nil
    category_matchers nil
    reserve nil
  end
end

