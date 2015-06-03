Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_with_shipping" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    with_shipping_price_current do
      next unless current_price
      current_price + listing.shipping_cost
    end

    with_shipping_price_list do
      next unless list_price
      list_price + listing.shipping_cost
    end

    with_shipping_price_sale do
      next unless sale_price
      sale_price + listing.shipping_cost
    end
  end
end
