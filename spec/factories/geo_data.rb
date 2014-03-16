FactoryGirl.define do
  factory :geo_data do
    sequence(:key) { |i| "key-#{i}"}
    data do
      {
        "city"=>"Salem",
        "state"=>"South Carolina",
        "country"=>"United States",
        "latitude"=>"34.9457089",
        "longitude"=>"-82.9716617",
        "state_code"=>"SC",
        "postal_code"=>"29676",
        "country_code"=>"US"
      }
    end
  end
end
