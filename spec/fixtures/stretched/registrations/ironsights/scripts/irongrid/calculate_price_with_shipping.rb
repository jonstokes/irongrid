Stretched::Script.define "ironsights/scripts/irongrid/calculate_price_with_shipping" do
  extensions 'ironsights/extensions/irongrid/*'
  script do
    price_with_shipping do
      next unless shipping_included?
      value = {}
      value.merge!(current: listing.price.current + shipping_cost) if listing.price.current
      value.merge!(list: list_price + shipping_cost) if list_price
      value.merge!(sale: listing.price.sale + shipping_cost) if listing.price.sale
      { price: value }
    end
  end
end
