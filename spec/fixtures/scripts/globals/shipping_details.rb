Loadable::Script.define do
  script "globals/shipping_details" do
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

