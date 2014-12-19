class MigrationWorker < CoreWorker

  sidekiq_options queue: :migration, retry: true

  def perform(listing_ids)
    IronBase::Settings.configure { |c| c.logger = nil }
    listing_ids.each do |id|
      listing = Listing.find id
      migrate(listing)
    end
  end

  def migrate(listing)
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