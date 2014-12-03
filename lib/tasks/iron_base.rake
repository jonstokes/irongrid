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

def correct_caliber_category(caliber)
  mappings.each do |mapping_name, mapping|
    return mapping_name.split("_calibers").first if mapping.has_term?(caliber, ignore_case: true)
  end
  nil
end

def correct_caliber(es_listing, listing)
  return unless listing['caliber']
  category = correct_caliber_category(listing.caliber)
  if category
    es_listing['product']['caliber_category'] = category
  else
    es_listing['product']['caliber'] = nil
  end
end

def correct_product_caliber(product)
  return unless product.caliber
  if category = correct_caliber_category(product.caliber)
    product.caliber_category = category
    product.save
  else
    product.caliber = nil
  end
end

def copy_listing(opts)
  listing, es_listing = opts[:source], opts[:destination]
  es_listing['id'] = Digest::MD5.hexdigest(listing.url)
  es_listing.inactive = !!listing.inactive
  es_listing['engine'] = 'ironsights'
  # es_listing.digest = listing.digest => This is set automatically now
  es_listing.url = {
      page: listing.bare_url,
      purchase: listing.url
  }
  es_listing.type = listing.type
  es_listing.title = listing.title
  es_listing.keywords = listing.keywords
  es_listing.description = listing.description
  es_listing.condition = listing.item_condition
  es_listing.auction_ends = listing.auction_ends
  es_listing['created_at'] = listing.created_at.utc
  es_listing['updated_at'] = listing.updated_at.utc
  es_listing.availability = listing.availability
  es_listing.image = {
      source: listing.image_source,
      cdn: listing.image,
      download_attempted: listing.image_download_attempted
  }
  es_listing.location = {
      id: listing.item_location.strip.upcase,
      city: listing.city,
      state: listing.state,
      country: listing.country,
      state_code: listing.state_code,
      postal_code: listing.postal_code,
      country_code: listing.country_code,
      coordinates: listing.coordinates
  }
  es_listing.with_shipping = {
      discount: {
          in_cents: listing.discount_in_cents_with_shipping,
          percent: listing.discount_percent_with_shipping
      },
      price: {
          current: listing.current_price_in_cents_with_shipping,
          per_round: listing.price_per_round_in_cents_with_shipping
      }
  }
  es_listing.discount = {
      in_cents: listing.discount_in_cents,
      percent: listing.discount_percent
  }
  es_listing.shipping = {
      cost: listing.shipping_cost_in_cents,
      included: !!listing.shipping_cost_in_cents
  }
  es_listing.price = {
      on_request: !!listing.price_on_request,
      current: listing.current_price_in_cents,
      per_round: listing.price_per_round_in_cents,
      list: listing.price_in_cents,
      sale: listing.sale_price_in_cents,
      buy_now: listing.buy_now_price_in_cents,
      current_bid: listing.current_bid_in_cents,
      mininum_bid: listing.minimum_bid_in_cents,
      reserve: listing.reserve_in_cents
  }
  es_listing.seller = {
      site_name: listing.seller_name,
      domain: listing.seller_domain
  }
  es_listing.product = {
      upc: listing.upc,
      sku: listing.sku,
      mpn: listing.mpn,
      category1: listing.category1,
      manufacturer: listing.manufacturer,
      caliber: listing.caliber,
      caliber_category: listing.caliber_category,
      number_of_rounds: listing.number_of_rounds,
      grains: listing.grains
  }
  correct_caliber(es_listing, listing)
  es_listing
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

def copy_product_to_index(listing)
  product_json = Hashie::Mash.new(
      engine: 'ironsights',
      upc: listing.upc,
      sku: listing.sku,
      mpn: listing.mpn,
      name: listing.title,
      long_description: listing.description,
      image: listing.image_source,
      image_download_attempted: listing.image_download_attempted,
      image_cdn: listing.image,
      msrp: listing.price_in_cents,
      category1: listing.category1,
      manufacturer: listing.manufacturer,
      weight: listing.weight_in_pounds,
      caliber: listing.caliber,
      caliber_category: listing.caliber_category,
      number_of_rounds: listing.number_of_rounds,
      grains: listing.grains,
      url: listing.url
  )

  product_json.category1 = nil unless category_is_hard_classified(listing)
  retryable(sleep: 0.5) { WriteProductToIndex.call(product_json: product_json) }.product
rescue Exception => e
  puts "## Listing #{listing.id} raised error #{e.message}. #{e.inspect} when indexing product"
  return nil
end

def category_is_hard_classified(listing)
  class_type = listing.item_data['category1'].detect {|h| h['classification_type']}['classification_type']
  %w(hard metadata).include?(class_type)
rescue
  nil
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
      product = copy_product_to_index(listing)
      correct_product_caliber(product) if product
    end
  end

  task products: :environment do
    include Retryable

    configure_synonyms
    index = create_index
    set_index(index)
    put_mappings

    Listing.where("type = 'RetailListing' AND upc IS NOT NULL").find_each do |listing|
      next unless listing.upc.present? && listing.upc[/[^0]+/]
      product = copy_product_to_index(listing)
      correct_product_caliber(product) if product
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