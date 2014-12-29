FactoryGirl.define do
  factory :product, class: IronBase::Product do

    to_create do |product|
      product.update_record_without_timestamping
    end

    transient do
      domain { 'www.retailer.com' }
      base_url { "http://#{domain}/" }
    end

    sequence(:id)    { |n| "1000#{n}" }
    sequence(:upc)   { |n| "1000#{n}" }
    sequence(:mpn)   { |n| "MPN-#{n}" }
    sequence(:sku)   { |n| "SKU-#{n}" }
    sequence(:name)  { |n| "Product Name - #{n}" }
    engine           { 'ironsights' }
    description do
      {
          short: 'Short description',
          long: 'Long description'
      }
    end
    image do
      {
          cdn: 'http://cdn.ironsights.com/1.jpg',
          source: "#{base_url}/1.jpg",
          download_attempted: true
      }
    end
    msrp             { 100}
    category1        { 'ammunition' }
    ammo_type        { 'cartridge' }
    weight           { { shipping: 10 } }
    manufacturer     { 'Remington'}
    caliber          { '.45 ACP' }
    caliber_category { 'handgun' }
    number_of_rounds { 50 }
    grains           { 120 }
    velocity         { 2400 }
    load_type        { '+P'}
    bullet_type      { 'FMJ' }
    material         { 'brass' }


    created_at { 2.days.ago.utc }
    updated_at { Time.now.utc }
  end
end


