Loadable::Script.define do
  script 'globals/product_details' do
    price_per_round_in_cents do |instance|
      listing = instance.listing
      next if listing.price.per_round
      next unless (listing.category1 == "Ammunition") &&
        listing.price.current && listing.product.number_of_rounds
      listing.price.per_round = (listing.price.current.to_f / listing.product.number_of_rounds.to_f).round rescue nil
    end
  end
end
