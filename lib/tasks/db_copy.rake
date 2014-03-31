namespace :db do
  namespace :copy do
    desc "Copy listings from one env to another"
    task :listings => :environment do
      include TaskHelper
      target_env = ENV['TARGET_ENV']
      source_env = Rails.env
      raise "Must set TARGET_ENV!" unless target_env
      raise "Cannot copy to production!" if target_env == "production"
      listing_skip_attrs = %w(
        item_data
        extended_item_data
        site_id
      )

      copy_listings(skip_attributes: listing_skip_attrs, source_env: source_env, target_env: target_env, batch_size: 1000)

      ActiveRecord::Base.establish_connection target_env
      Listing.find_each do |listing|
        geo_data_id = GeoData.get(listing.item_location).id
        listing.update_attribute(:geo_data_id, geo_data_id)
      end
    end

    desc "Copy parser tests from one env to another"
    task :parser_tests => :environment do
      include TaskHelper
      target_env = ENV['TARGET_ENV']
      source_env = Rails.env
      raise "Must set TARGET_ENV!" unless target_env
      raise "Cannot copy to production!" if target_env == "production"

      pt_skip_attrs = %w(
        manufacturer
        caliber
        caliber_category
        number_of_rounds
        grains
        model
        barrel_length
        item_data
      )
      opts = {
        klass: ParserTest,
        skip_attributes: pt_skip_attrs,
        source_env: source_env,
        target_env: target_env,
        batch_size: 100
      }
      copy_table(opts)
      puts "Found #{ParserTest.count} parser tests in #{target_env} database."
    end
  end
end
