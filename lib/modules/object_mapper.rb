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

  def reverse_map(listing)
    json = Hashie::Mash.new

    %w(engine type title keywords description condition auction_ends availability).each do |attr|
      json[attr] = listing[attr]
    end

    json.url = listing.url.purchase
    json.shipping_cost_in_cents = listing.shipping_cost
    json.image = listing.image.source
    json.location = listing.location.try(:source)
    json.discount_in_cents = listing.discount.try(:in_cents)
    json.discount_percent = listing.discount.try(:percent)
    json.price_on_request = listing.price.try(:on_request)
    json.current_price_in_cents = listing.price.try(:current)
    json.price_in_cents = listing.price.try(:list)
    json.sale_price_in_cents = listing.price.try(:sale)
    json.buy_now_price_in_cents = listing.price.try(:buy_now)
    json.current_bid_in_cents = listing.price.try(:current_bid)
    json.minimum_bid_in_cents = listing.price.try(:minimum_bid)
    json.reserve_in_cents = listing.price.try(:reserve)
    json.price_per_round_in_cents = listing.price.try(:per_round)
    json.product_upc = listing.product.upc
    json.product_sku = listing.product.sku
    json.product_mpn = listing.product.mpn
    json.product_category1 = listing.product.category1
    json.product_manufacturer = listing.product.manufacturer
    json.weight_in_pounds = listing.product.shipping
    json.product_caliber = listing.product.caliber
    json.product_caliber_category = listing.product.caliber_category
    json.product_number_of_rounds = listing.product.number_of_rounds
    json.product_grains = listing.product.grains
    json
  end
end
