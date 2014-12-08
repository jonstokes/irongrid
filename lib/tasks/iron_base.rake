def timestamp
  Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S')
end

def generate_index_name
  "ironsights-#{Rails.env}-#{timestamp}"
end

def set_index(index_name)
  IronBase::Settings.configure { |c| c.elasticsearch_index = index_name }
end

def put_mappings
  IronBase::Listing.put_mapping
  IronBase::Product.put_mapping
  Location.put_mapping
end

def configure_synonyms
  IronBase::Settings.configure do |config|
    config.synonyms = ElasticTools::Synonyms.synonyms
  end
end

def create_index
  index_name = generate_index_name
  IronBase::Index.create(
      index: index_name,
      filename: 'ironsights_v1.yml'
  )
  sleep 5
  index_name
end

def create_alias(index_name)
  IronBase::Index.create_alias(
      index: index_name,
      alias: 'ironsights'
  )
end

def turn_on_logging
  IronBase::Settings.configure {|c| c.logger = Rails.logger}
end

namespace :index do
  task create: :environment do
    configure_synonyms
    index = create_index
    set_index(index)
    put_mappings
  end

  task create_with_alias: :environment do
    configure_synonyms
    index = create_index
    set_index(index)
    put_mappings
    create_alias(index)
  end
end

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

  task listings: :environment do
    include Retryable

    Listing.find_each do |listing|
      ListingMigration.new(listing).write_json_to_stretched_queue
      sleep 1 # Throttle so that the grid can keep up and redis doesn't get filled
    end
  end

  task listing_data: :environment do
    Listing.find_each do |listing|
      es_listing = IronBase::Listing.find
    end
  end
end