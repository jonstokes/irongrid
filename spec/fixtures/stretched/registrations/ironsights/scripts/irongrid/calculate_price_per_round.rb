Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_per_round" do
  extensions 'ironsights/extensions/irongrid/*'
  script do
    price_per_round do
      next unless should_calculate_ppr? && listing.price.current
      calculate_price_per_round(listing.price.current)
    end
  end
end