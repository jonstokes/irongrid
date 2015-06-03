Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_per_round" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    price_per_round do
      next unless should_calculate_ppr?
      calculate_price_per_round(current_price)
    end
  end
end
