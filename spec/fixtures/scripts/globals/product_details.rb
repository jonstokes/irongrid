Loadable::Script.define do
  script 'globals/product_details' do
    price_per_round_in_cents do |instance|
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
  end
end
