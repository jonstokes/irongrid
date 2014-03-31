module TaskHelper

  def copy_table(opts)
    source_env, target_env, klass = opts[:source_env], opts[:target_env], opts[:klass]
    raise "Can't copy to production!" if target_env == "production"
    puts "COPYING table #{klass.to_s}, #{source_env} => #{target_env}"
    sleep 3

    ActiveRecord::Base.establish_connection target_env
    puts "Found #{klass.count} #{klass.to_s.pluralize.downcase} in target #{target_env} database."
    ActiveRecord::Base.establish_connection source_env
    puts "Found #{klass.count} #{klass.to_s.pluralize.downcase} in source #{source_env} database."

    klass.find_in_batches do |batch|
      copy_batch(opts.merge(batch: batch))
    end
  end

  def copy_batch(opts)
    source_env, target_env, batch, klass, copy_id = opts[:source_env], opts[:target_env], opts[:batch], opts[:klass], opts[:copy_id]
    raise "Can't copy to production!" if target_env == "production"
    ActiveRecord::Base.establish_connection target_env

    skip_attributes = ["", "extended_item_data"]
    skip_attributes += opts[:skip_attributes] if opts[:skip_attributes]

    batch.each do |item|
      attrs = {}
      klass.accessible_attributes.each do |attr|
        next if skip_attributes.include?(attr)
        attrs.merge!(attr => item.send(attr))
      end
      attrs.merge!("id" => item.id) if copy_id
      klass.create(attrs)
    end
    ActiveRecord::Base.establish_connection source_env
  end

  def copy_listings(opts)
    Listing.disable_index_updates!
    source_env, target_env = opts[:source_env], opts[:target_env]
    raise "Can't copy to production!" if target_env == "production"
    batch_size = opts[:batch_size] || 200
    opts[:klass] = Listing

    ActiveRecord::Base.establish_connection target_env
    puts "Found #{Listing.count} listings in target #{target_env} database."
    ActiveRecord::Base.establish_connection source_env
    puts "Found #{Listing.count} listings in source #{source_env} database."

    geo_batch = Set.new
    [RetailListing, ClassifiedListing, AuctionListing].each do |listing_type|
      listing_batch = []
      listing_type.limit(batch_size).each do |listing|
        listing_batch << listing
        geo_batch << listing.geo_data
      end
      copy_batch(opts.merge(batch: listing_batch))
    end
    copy_batch(opts.merge(batch: geo_batch, klass: GeoData, copy_id: true))
  end
end
