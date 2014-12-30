class MigrationWorker < CoreWorker

  sidekiq_options queue: :migration, retry: true

  def perform(opts)
    opts.symbolize_keys!
    klass, record_ids = opts[:klass].constantize, opts[:record_ids]
    IronBase::Settings.configure { |c| c.logger = nil }
    IronBase::Listing.run_percolators = false
    record_ids.each do |id|
      obj = klass.find id
      if klass == Listing
        migrate_listing(obj)
      else
        migrate_location(obj)
      end
    end
  end

  def migrate_location(loc)
    IronBase::Location.create(
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
  rescue Exception => e
    puts "# Location #{loc.id} raised error #{e.message}."
    puts "#{e.backtrace}"
  end

  def migrate_listing(listing)
    migration = ListingMigration.new(listing)
    migration.write_listing_to_index
    migration.verify
    migration.fix_listing_metadata
    migration = nil
  rescue Exception => e
    puts "# Listing #{listing.id} raised error #{e.message}."
    puts "#{e.backtrace}"
  end
end