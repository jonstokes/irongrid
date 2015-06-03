Stretched::Script.define "ironsights/scripts/irongrid/calculate_discount" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    discount_in_cents do
      calculate_discount_in_cents(list_price, current_price) || 0
    end

    discount_percent do
      calculate_discount_percent(list_price, current_price) || 0
    end
  end
end
