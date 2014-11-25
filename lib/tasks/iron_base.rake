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
  return unless listing['caliber']
  category = correct_caliber_category(listing)
  if category
    es_listing['product']['caliber_category'] = category
  else
    es_listing['product']['caliber'] = nil
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
      weight: {
          shipping: listing.weight_in_pounds
      },
      caliber: listing.caliber,
      caliber_category: listing.caliber_category,
      number_of_rounds: listing.number_of_rounds,
      grains: listing.grains
  }
  correct_caliber(es_listing, listing)
end

namespace :index do
  task create: :environment do
    IronBase::Settings.configure do |config|
      config.synonyms = ElasticTools::Synonyms.synonyms
    end

    index_name = generate_index_name
    IronBase::Index.create(
        index: index_name,
        filename: 'ironsights_v1.yml'
    )
    sleep 5
    IronBase::Settings.configure { |c| c.elasticsearch_index = index_name }
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
    IronBase::Settings.configure { |c| c.elasticsearch_index = index_name }
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
    include Retryable
    IronBase::Listing.record_timestamps = false
    IronBase::Listing.run_percolators = false

    Listing.find_each do |listing|
      retryable do
        es_listing = IronBase::Listing.new
        copy_listing(source: listing, destination: es_listing)
        es_listing.send(:run_validations)
        es_listing.send(:set_digest!)
        es_listing.send(:persist!)
      end
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