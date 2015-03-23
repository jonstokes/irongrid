Loaded::Script.define "ironsights/globals/calculate_discount" do
  extensions 'ironsights/globals/extensions/*'
  script do
    discount do
      next if discounted? || !list_price
      {
          in_cents: calculate_discount_in_cents(list_price, listing.price.current),
          percent: calculate_discount_percent(list_price, listing.price.current)
      }
    end
  end
end
