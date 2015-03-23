Loaded::Script.define "ironsights/globals/calculate_price_with_shipping" do
  extensions 'ironsights/globals/extensions/*'
  script do
    price_with_shipping do
      next unless shipping_included?
      value = {}
      value.merge!(current: listing.price.current + shipping.cost) if listing.price.current
      value.merge!(list: list_price + shipping.cost) if list_price
      value.merge!(sale: listing.price.sale + shipping.cost) if listing.price.sale
      { price: value }
    end
  end
end
