Loadable::Script.define do
  script "ironsights/globals/calculate_price_per_round_with_shipping" do
    price_per_round_with_shipping do
      next unless shipping_included? && should_calculate_ppr?
      calculate_price_per_round(with_shipping.price.current)
    end
  end
end