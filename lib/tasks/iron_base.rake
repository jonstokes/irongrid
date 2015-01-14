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
  IronBase::Location.put_mapping
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

def migrate(listing)
  migration = ListingMigration.new(listing)
  migration.write_listing_to_index
  migration.verify
  migration.fix_listing_metadata
rescue Exception => e
  puts "# Listing #{listing.id} raised error #{e.message}."
  puts "#{e.backtrace}"
end

def wait_for_jobs(klass)
  while klass._jobs.any?
    sleep 0.5
  end
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

namespace :delete do
  task listings: :environment do
    search = IronBase::Search::Search.new
    seller_domains = %w(
      www.brownells.com
      www.guncasket.com
      www.policestore.com
      www.sinclairintl.com
      www.sportsmanswarehouse.com
    )
    search.filters << { seller_domain: seller_domains }
    IronBase::Listing.find_each(search.query_hash) do |batch|
      DeleteListingsWorker.perform_async(batch.map(&id))
      wait_for_jobs(DeleteListingsWorker)
    end
  end
end

namespace :migrate do
  task geo_data: :environment do
    IronBase::Settings.configure { |c| c.logger = nil }
    GeoData.find_in_batches do |batch|
      MigrationWorker.perform_async(klass: 'GeoData', record_ids: batch.map(&:id))
      wait_for_jobs(MigrationWorker)
    end
  end

  task script_sites: :environment do
    include Retryable
    Rails.application.eager_load!
    IronBase::Settings.configure { |c| c.logger = nil }

    domains = [
        'www.midwayusa.com',
        'www.brownells.com',
        'www.budsgunshop.com',
        'www.deansgunshop.com',
        'www.highplainsgun.com',
        'www.hitekestore.com',
        'www.hyattgunstore.com',
        'www.hoosierarmory.com',
        'www.ironsightsguns.com',
        'www.lg-outdoors.com',
        'www.midwayusa.com',
        'www.mrgundealer.com',
        'www.premiertactical.com',
        'www.schuylerarmsco.com',
        'www.sfarmory.com',
        'www.sheridanoutfittersinc.com',
        'www.sportsmanswarehouse.com',
        'www.zxgun.biz'
    ]

    Listing.where(seller_domain: domains).find_in_batches do |batch|
      MigrationWorker.perform_async(batch.map(&:id))
      wait_for_jobs(MigrationWorker)
    end
  end

  task listings: :environment do
    include Retryable
    Rails.application.eager_load!

    IronBase::Settings.configure { |c| c.logger = nil }
    Listing.find_in_batches do |batch|
      MigrationWorker.perform_async(klass: 'Listing', record_ids: batch.map(&:id))
      wait_for_jobs(MigrationWorker)
    end
  end
end