namespace :migrate do
  task geo_data: :environment do
    GeoData.find_each do |loc|
      Location.create(
          id: loc.key,
          city: loc.city,
          state: loc.state,
          country: loc.country,
          latitude: loc.latitude,
          longitude: loc.longitude,
          state_code: loc.state_code,
          postal_code: loc.postal_code,
          country_code: loc.country_code
      )
    end
  end
end