Loadable::Script.define do
  script "ironsights/globals/calculate_discount_with_shipping" do
    discount_with_shipping do
      next unless shipping_included? && discounted?
      {
          in_cents: calculate_discount_in_cents(list_price, with_shipping.price.current),
          percent:  calculate_discount_percent(list_price, with_shipping.price.current)
      }
    end
  end
end