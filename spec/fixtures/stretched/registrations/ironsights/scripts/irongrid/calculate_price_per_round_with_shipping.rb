Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_per_round_with_shipping" do
  extensions 'ironsights/extensions/irongrid/*'
  script do
    price_per_round_with_shipping do
      next unless shipping_included? && should_calculate_ppr? && with_shipping.price.current
      calculate_price_per_round(with_shipping.price.current)
    end
  end
end