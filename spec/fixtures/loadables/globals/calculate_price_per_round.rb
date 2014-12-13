Loadable::Script.define do
  script "ironsights/globals/calculate_price_per_round" do
    price_per_round do
      next unless should_calculate_ppr?
      calculate_price_per_round(listing.price.current)
    end
  end
end