Stretched::Script.define "ironsights/scripts/irongrid/calculate_discount_with_shipping" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    with_shipping_discount_in_cents do
      calculate_discount_in_cents(list_price, listing.with_shipping_price_current) || 0
    end

    with_shipping_discount_percent do
      calculate_discount_percent(list_price, listing.with_shipping_price_current) || 0
    end
  end
end
