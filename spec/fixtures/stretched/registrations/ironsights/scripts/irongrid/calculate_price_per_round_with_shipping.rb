Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_per_round_with_shipping" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    with_shipping_price_per_round do
      next unless should_calculate_ppr? && listing.with_shipping_price_current
      calculate_price_per_round(listing.with_shipping_price_current)
    end
  end
end
