def timestamp
  Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S')
end

def generate_index_name
  "ironsights-#{Rails.env}-#{timestamp}"
end

def put_mappings
  IronBase::Listing.put_mapping
  IronBase::Product.put_mapping
  Location.put_mapping
end

def json_mapping
  @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/listing_postgres.yml"
end

def mappings
  @mappings ||= begin
    list = {}
    %w(rimfire_calibers handgun_calibers shotgun_calibers rifle_calibers).each do |key|
      list.merge!(key => Stretched::Mapping.find(key))
    end
    list
  end
end

def correct_caliber_category(listing)
  mappings.each do |mapping_name, mapping|
    return mapping_name.split("_calibers").first if mapping.has_term?(listing.caliber, ignore_case: true)
  end
  nil
end

def correct_caliber(es_listing, listing)
  return unless listing.caliber
  category = correct_caliber_category(listing)
  if category
    es_listing.product.caliber_category = category
  else
    es_listing.product.caliber = nil
  end
end

def copy_listing(opts)
  ObjectMapper.transform(opts.merge(mapping: json_mapping))
  listing, es_listing = opts[:source], opts[:destination]
  es_listing.id = listing.url
  es_listing.engine = 'ironsights'
  correct_caliber(es_listing, listing)
  es_listing.updated_at = listing.updated_at.utc
  es_listing.created_at = listing.created_at.utc
end

namespace :index do
  task create: :environment do
    IronBase::Settings.configure do |config|
      config.synonyms = ElasticTools::Synonyms.synonyms
    end

    IronBase::Index.create(
        index: index_name,
        filename: 'ironsights_v1.yml'
    )
    sleep 5
    put_mappings
  end

  task create_with_alias: :environment do
    index_name = generate_index_name
    IronBase::Settings.configure do |config|
      config.synonyms = ElasticTools::Synonyms.synonyms
    end

    IronBase::Index.create(
        index: index_name,
        filename: 'ironsights_v1.yml'
    )
    sleep 5
    put_mappings
    sleep 5
    IronBase::Index.create_alias(
        index: index_name,
        alias: 'ironsights'
    )
  end
end

namespace :migrate do
  task listings: :environment do
    IronBase::Listing.record_timestamps = false
    IronBase::Listing.run_percolators = false

    Listing.find_each do |listing|
      es_listing = IronBase::Listing.new
      copy_listing(source: listing, destination: es_listing)
      es_listing.send(:run_validations)
      es_listing.send(:set_digest!)
      es_listing.send(:persist!)
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