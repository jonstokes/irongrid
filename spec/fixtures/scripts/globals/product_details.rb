Loadable::Script.define do
  script 'globals/product_details' do
    # next unless shipping cost
    #   current price with shipping = current price + shipping cost
    # next unless discount
    #   discount with shipping = list price - current price with shipping
    #   discount percent with shipping = (list price / current price with shipping) * 100

    # next unless price per round
    #   current_ppr = current price / number of rounds
    #   list_ppr = list price / number of rounds
    #
    #   next unless shipping_cost
    #     current_ppr with shipping = current price with shipping / num rounds
    #
    # next unless discount
    #   ppr_discount = list_ppr - current_ppr
    #   ppr_discount_percent = (list_ppr / current_ppr).round * 100
    #
    #   next unless shipping_cost
    #     discount ppr with shipping = list_ppr - current_ppr with shipping
    #     discount ppr percent with shipping = (list_ppr / current_ppr with shipping).round * 100
    

   price_per_round do |instance|
      listing = instance.listing
      next if listing.price.per_round
      next unless (listing.category1 == "Ammunition") &&
        listing.price.current && listing.product.number_of_rounds
      listing.price.per_round = (listing.price.current.to_f / listing.product.number_of_rounds.to_f).round rescue nil
    end

    discount_ppr_percent do |instance|
      listing = instance.listing
      next unless listing.discount && listing.price.per_round
      list_ppr = (listing.price.list.to_f / listing.product.number_of_rounds.to_f).round
      listing.discount.ppr_percent = (listing.price.per_round / list_ppr.to_f).round * 100
    end

    current_price_with_shipping do |instance|
      listing = instance.listing
      next unless listing.price && listing.price.current
      listing.with_shipping ||= {}
      current_with_shipping = if listing.shipping_cost
                                listing.price.current + listing.shipping_cost
                              else
                                listing.price.current
                              end
      listing.with_shipping.merge!(price: { current: current_with_shipping })
    end

    price_per_round_with_shipping do |instance|
      listing = instance.listing
      next unless listing.with_shipping && listing.price.per_round
      shipping_ppr = if listing.shipping_cost
                       listing.price.per_round + (listing.shipping_cost.to_f / listing.product.number_of_rounds.to_f).round
                     else
                       listing.price_per_round
                     end
      listing.with_shipping.price.merge!(per_round: shipping_ppr)
    end

    discount_with_shipping do |instance|
      listing = instance.listing
      next unless listing.with_shipping && listing.discount
      discount = if listing.shipping_cost
                   discount = listing.discount.in_cents - listing.shipping_cost
                   (discount > 0) ? discount : 0
                 else
                   listing.discount.in_cents
                 end
      listing.with_shipping.discount = { in_cents: discount }
    end

    discount_percent_with_shipping do |instance|
      listing = instance.listing
      next unless listing.with_shipping.discount.in_cents
      listing.with_shipping.discount.percent =
          ((listing.with_shipping.discount.in_cents.to_f / listing.price.current.to_f) * 100).to_i
    end

    discount_ppr_percent_with_shipping do |instance|
      listing = instance.listing
      next unless listing.with_shipping.discount && listing.price.per_round
    end
  end
end
