module ObjectMapper
  def transform(opts)
    json, listing, mapping = opts[:source], opts[:destination], opts[:mapping]
    mapping.each do |key, value|
      if value.is_a?(Hashie::Mash)
        field = Hashie::Mash.new
        nopts = {
            source: json,
            destination: field,
            mapping: value
        }
        transform(nopts)
        listing[key] = field unless field.empty?
      else
        next unless json[value]
        listing[key] = json[value]
      end
    end
  end

  #
  # The following functions are just used for specs
  #

  def json_from_listing(listing)
    reverse_map(listing).to_hash.deep_symbolize_keys.merge(valid: true).except(:url)
  end

  def reverse_map(listing)
    json = Hashie::Mash.new

    %w(engine type title keywords description condition auction_ends availability).each do |attr|
      json[attr] = listing[attr]
    end

    json.url = listing['url']['purchase']
    json.shipping_cost_in_cents = listing['shipping']['cost']
    json.image = listing['image']['source']
    json.location = listing['location']['source'] rescue nil
    json.discount_in_cents = listing['discount']['in_cents'] rescue nil
    json.discount_percent = listing['discount']['percent'] rescue nil
    json.price_on_request = listing['price']['on_request'] rescue nil
    json.current_price_in_cents = listing['price']['current'] rescue nil
    json.price_in_cents = listing['price']['list'] rescue nil
    json.sale_price_in_cents = listing['price']['sale'] rescue nil
    json.buy_now_price_in_cents = listing['price']['buy_now'] rescue nil
    json.current_bid_in_cents = listing['price']['current_bid'] rescue nil
    json.minimum_bid_in_cents = listing['price']['minimum_bid'] rescue nil
    json.reserve_in_cents = listing['price']['reserve'] rescue nil
    json.price_per_round_in_cents = listing['price']['per_round'] rescue nil
    json.product_upc = listing['product']['upc']
    json.product_sku = listing['product']['sku']
    json.product_mpn = listing['product']['mpn']
    json.product_category1 = listing['product']['category1']
    json.product_manufacturer = listing['product']['manufacturer']
    json.weight_in_pounds = listing['product']['shipping']
    json.product_caliber = listing['product']['caliber']
    json.product_caliber_category = listing['product']['caliber_category']
    json.product_number_of_rounds = listing['product']['number_of_rounds']
    json.product_grains = listing['product']['grains']
    json
  end

  class Mapper
    include ObjectMapper
  end

  def self.transform(opts)
    Mapper.new.transform(opts)
  end

  def self.json_from_listing(listing)
    Mapper.new.json_from_listing(listing)
  end
end
