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

namespace :index do
  task create: :environment do
    IronBase::Settings.configure do |config|
      config.synonyms = ElasticTools::Synonyms.synonyms
    end

    IronBase::Index.create(
        index: index_name,
        filename: 'ironsights_v1'
    )
    put_mappings
  end

  task create_with_alias: :environment do
    index_name = generate_index_name
    IronBase::Settings.configure do |config|
      config.synonyms = ElasticTools::Synonyms.synonyms
    end

    IronBase::Index.create(
        index: index_name,
        filename: 'ironsights_v1'
    )
    put_mappings
    IronBase::Index.create_alias(
        index: index_name,
        alias: 'listings'
    )
  end
end