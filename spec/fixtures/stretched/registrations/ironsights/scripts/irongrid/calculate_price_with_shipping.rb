Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_with_shipping" do
  extensions [
    'globals/extensions/*',
    'ironsights/extensions/irongrid/*'
  ]

  script do
    with_shipping_price_current do
      current_price + listing.shipping_cost
    end

    with_shipping_price_list do
      list_price + listing.shipping_cost
    end

    with_shipping_price_sale do
      sale_price + listing.shipping_cost
    end
  end
end
