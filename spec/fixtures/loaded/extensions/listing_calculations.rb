Loaded::Extension.define "ironsights/globals/extensions/listing_calculations" do
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

    def current_price
      listing.price.try(:current)
    end

    def discounted?
      listing.discount.try(:in_cents) && !listing.discount.in_cents.zero?
    end

    def with_shipping
      listing.with_shipping ||= {}
    end

    def weight
      product.weight.try(:shipping)
    end

    def shipping
      listing.shipping ||= {}
    end

    def shipping_included?
      shipping.included ||= !!shipping.cost
    end

    def number_of_rounds
      product.number_of_rounds
    end

    def list_price_per_round
      if list_price
        (list_price.to_f / number_of_rounds.to_f).round.to_i
      end
    end

    def list_price
      listing.price.list || product.msrp
    end

    def calculate_price_per_round(price)
      (price.to_f / number_of_rounds.to_f).round.to_i
    end

    def calculate_discount_in_cents(list, sale)
      return 0 unless list > sale
      list - sale
    end

    def calculate_discount_percent(list, sale)
      return 0 unless (list > sale) && !sale.zero?
      discount_amount = calculate_discount_in_cents(list, sale)
      ((discount_amount.to_f / list.to_f) * 100).round
    end

    def should_calculate_ppr?
      product.ammunition? && number_of_rounds && !number_of_rounds.zero?
    end
  end
end
