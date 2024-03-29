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

def tfb_domains
  [
    'www.academy.com',
    'www.ammo-sale.com',
    'www.ammunitiontogo.com',
    'www.botach.com',
    'www.brownells.com',
    'www.cheaperthandirt.com',
    'www.luckygunner.com',
    'www.manventureoutpost.com',
    'www.midwayusa.com',
    'palmettostatearmory.com',
    'www.selwayarmory.com',
    'www.sinclairintl.com',
    'www.sportsmanswarehouse.com',
    'www.swva-arms.com',
    'www.targetsportsusa.com',
    'www.ammunitiondepot.com',
    'bangitammo.com',
    'www.policestore.com',
    'www.venturamunitions.com',
    'all-in-general.com',
    'www.lanbosarmory.com'
  ]
end

def tfb_calibers
  [
    '.17 HMR',
    '.22lr',
    '.22 WMR',
    '.22-250',
    '.223 Rem',
    '.300 BLK',
    '.30-30 Win',
    '.30-06',
    '.308 Win',
    '.338 Lapua Mag',
    '.357 Mag',
    '.380 ACP',
    '.38 Special',
    '.40 S&W',
    '.44 Mag',
    '.45 ACP',
    '.45 Long Colt',
    '5.45x39mm',
    '5.56 NATO',
    '5.7x28mm',
    '6.5mm Grendel',
    '6.8mm Rem SPC',
    '7.62x39mm',
    '7.62x54R',
    '9mm Luger',
    '10mm Auto',
    '12 gauge',
    '20 gauge'
  ]
end

def tfb_body
  {
    filter: {
      bool: {
        must: [
          { term:   { engine:                            'ironsights' } },
          { term:   { 'listing.product.category1.raw' => 'ammunition' } },
          { exists: { field: 'listing.product.caliber.raw' } },
          { terms:  { "listing.seller.domain"         => tfb_domains } }
        ],
        must_not: [
          { term:   { availability:                       'out_of_stock'} },
          { term:   { inactive:                           true }}
        ]
      }
    }
  }
end

namespace :tfb do
  task create_alias: :environment do
    IronBase::Index.create_alias(
      index: "restored_ironsights-production-2015-01-14-00-19-56",
      alias: "tfb",
      body: tfb_body
    )
  end

  task update_alias: :environment do
    IronBase::Index.update_alias(
      index: "restored_ironsights-production-2015-01-14-00-19-56",
      alias: "tfb",
      body: tfb_body
    )
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

namespace :snapshot do
  task create_repository: :environment do
    result = IronBase::Snapshot.create_repository
    puts "#{result}"
  end

  task create: :environment do
    result = IronBase::Snapshot.create(indexes: IronBase::Settings.elasticsearch_index)
    puts "#{result}"
  end

end

namespace :delete do
  task listings: :environment do
    search = IronBase::Search::Search.new
    seller_domains = %w(
      www.brownells.com
      www.midwayusa.com
    )
    search.filters.merge!(seller_domain: seller_domains)
    IronBase::Listing.find_each(search.query_hash) do |batch|
      DeleteListingsWorker.perform_async(batch.map(&:id))
      wait_for_jobs(DeleteListingsWorker)
    end
  end
end

namespace :products do
  task rebuild: :environment do
    sources = [
      #'www.luckygunner.com',
      #'www.midwayusa.com',
      'www.cheaperthandirt.com'
      ]

    #delete_all_products
    rebuild_products_from_sources(sources)
  end

  task relink: :environment do
    sources = [
      'www.brownells.com',
      'www.manventureoutpost.com',
      'www.sportsmanswarehouse.com',
      'www.botach.com'
    ]
    rebuild_products_from_sources(sources, false)
  end
end

def delete_all_products
  puts "Deleting all products in the products database..."
  IronBase::Product.find_each do |batch|
    IronBase::Product.bulk_delete batch.map(&:id)
  end
end

def listings_for_site(domain)
  IronBase::Listing.new_search(
    filters: {
      seller_domain: domain
    }
  )
end

def rebuild_product(opts)
  listing = opts[:listing]
  rebuild = opts[:rebuild]

  upc = listing.product_source.upc
  return if rebuild && upc.nil?

  product = IronBase::Product.find_by_upc(upc).first || IronBase::Product.new

  # Fill in any empty product attributes using this listing
  result = UpdateProductFromListing.call(product: product, listing: listing)
  listing = result.listing
  product = result.product

  # Fill in any empty listing.product_source attributes from the product
  result = UpdateListingFromProduct.call(product: product, listing: listing)
  listing = result.listing
  product = result.product

  product.save(prune_invalid_attributes: true) if rebuild

  listing.update_record_without_timestamping
end

def rebuild_products_from_sources(sources, rebuild=true)
  sources.each do |domain|
    puts "Rebuilding products for #{domain}..."
    listings_for_site(domain).find_each do |batch|
      batch.each do |listing|
        Retryable.retryable(sleep: 2, tries: 3) do
          rebuild_product(
            listing: listing,
            rebuild: rebuild,
          )
        end
      end
      puts "  rebuilt products from #{batch.size} listings"
    end
  end
end

namespace :migrate do
  task fix_products: :environment do
    IronBase::Listing.record_timestamps = false
    IronBase::Listing.find_each do |listing|
      update_product(listing)
    end
  end

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
