Stretched::Extension.define "ironsights/extensions/irongrid/listing_calculations" do
  extension do
    def listing
      context[:listing]
    end

    def product
      context[:product]
    end

    def listing_json
      context[:listing_json]
    end

    def with_shipping
      listing.with_shipping
    end

    def shipping
      listing.shipping
    end

    def message1
      listing_json.message1
    end

    def message2
      listing_json.message2
    end

    def message3
      listing_json.message3
    end

    def message4
      listing_json.message4
    end

    def list_price
      listing.price_list || product.msrp || 0
    end

    def current_price
      listing.price_current || 0
    end

    def sale_price
      listing.price_sale || 0
    end

    def discounted?
      listing.discount_in_cents && !listing.discount_in_cents.zero?
    end

    def weight
      product.weight.try(:shipping)
    end

    def shipping_included?
      listing.shipping_included?
    end

    def number_of_rounds
      product.number_of_rounds
    end

    def calculate_price_per_round(price)
      (price.to_f / number_of_rounds.to_f).round.to_i
    end

    def should_calculate_ppr?
      product.ammunition? && number_of_rounds && !number_of_rounds.zero?
    end
  end
end
