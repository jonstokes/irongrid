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

def copy_listing_to_index(listing)
  es_listing = IronBase::Listing.new
  retryable do
    copy_listing(source: listing, destination: es_listing)
    es_listing.send(:run_validations)
    es_listing.send(:set_digest!)
    es_listing.send(:persist!)
  end
  return es_listing
rescue Exception => e
  puts "## Listing #{listing.id} raised error #{e.message}. #{e.inspect} when indexing listing"
  return nil
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

task build_products: :environment do
  query_hash = {
      query: {
          filtered: {
              filter: {
                  bool: {
                      must: [
                          { exists: { field: 'product_source.upc' } },
                          { term: { type: 'RetailListing' } }
                      ]
                  }
              }
          }
      }
  }
  IronBase::Listing.find_each(query_hash) do |batch|
    batch.each do |listing|
      WriteProductToIndex.call(product_json: listing.product_source)
    end
  end
end

namespace :migrate do
  task listings: :environment do
    include Retryable
    IronBase::Listing.record_timestamps = false
    IronBase::Listing.run_percolators = false

    configure_synonyms
    index = create_index
    set_index(index)
    put_mappings

    Listing.find_each do |listing|
      copy_listing_to_index(listing)
    end
  end

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