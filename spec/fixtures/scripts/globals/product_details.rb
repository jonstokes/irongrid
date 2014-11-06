Loadable::Script.define do
  script 'globals/product_details' do
    # next unless shipping cost
    #   current price with shipping = current price + shipping cost
    # next unless discount
    #   discount with shipping = list price - current price with shipping
    #   discount percent with shipping = (list price / current price with shipping) * 100

    # next unless number of rounds
    #   current_ppr = current price / number of rounds
    #
    #   if shipping_cost
    #     current_ppr with shipping = current price with shipping / num rounds
    #
    # next unless discount
    #   list_ppr = list price / number of rounds
    #   ppr_discount = list_ppr - current_ppr
    #   ppr_discount_percent = (list_ppr / current_ppr).round * 100
    #
    #   if shipping_cost
    #     discount ppr with shipping = list_ppr - current_ppr with shipping
    #     discount ppr percent with shipping = (list_ppr / current_ppr with shipping).round * 100


    with_shipping do |instance|
      listing = instance.listing

      # current price with shipping
      next unless listing.shipping_cost && listing.price.try(:current)
      listing.with_shipping = {
          price: {
              current: (listing.price.current + listing.shipping_cost)
          }
      }

      # discount with shipping
      next unless listing.discount.try(:in_cents)
      listing.with_shipping.merge!(
          discount: {
              in_cents: listing.price.current.list - listing.with_shipping.price.current,
              percent: (listing.price.current.list.to_f / listing.with_shipping.price.current.to_f).round * 100
          }
      )
    end

    price_per_round do |instance|
      listing = instance.listing

      # current price per round
      next unless listing.ammo? && listing.product.number_of_rounds
      listing.price.per_round =
          (listing.price.current.to_f / listing.product.number_of_rounds.to_f).round.to_i

      # current price per round with shipping
      if listing.with_shipping
        listing.with_shipping.price.per_round =
            (listing.with_shipping.price.current.to_f / listing.product.number_of_rounds.to_f).round.to_i
      end

      # ppr discounts
      next unless listing.discount
      list_ppr = (listing.price.list.to_f / listing.product.number_of_rounds.to_f).round.to_i
      ppr_discount = list_ppr - listing.price.per_round
      listing.discount.ppr_percent = (list_ppr.to_f / current_ppr.to_f).round * 100

      # ppr discounts with shipping
      if listing.with_shipping
        ppr_discount_with_shipping = list_ppr - listing.with_shipping.price.per_round
        listing.with_shipping.discount.ppr_percent = (list_ppr.to_f / ppr_discount_with_shipping.to_f).round * 100
      end
    end
  end
end
