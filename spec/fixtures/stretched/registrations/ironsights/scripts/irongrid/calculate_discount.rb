Stretched::Script.define "ironsights/scripts/irongrid/calculate_discount" do
  extensions 'ironsights/extensions/irongrid/*'
  script do
    discount do
      next if discounted?
      next unless list_price && listing.price.current
      {
          in_cents: calculate_discount_in_cents(list_price, listing.price.current),
          percent: calculate_discount_percent(list_price, listing.price.current)
      }
    end
  end
end
