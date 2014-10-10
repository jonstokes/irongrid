Loadable::Script.define do
  script "globals/shipping_details" do
    current_price_in_cents_with_shipping do |instance|
      next unless instance[:current_price_in_cents]
      next instance[:current_price_in_cents] unless instance[:shipping_cost_in_cents]
      instance[:current_price_in_cents] + instance[:shipping_cost_in_cents]

    end

    price_per_round_in_cents_with_shipping do |instance|
      next unless instance[:shipping_cost_in_cents] && instance[:price_per_round_in_cents]
      instance[:price_per_round_in_cents] + (instance[:shipping_cost_in_cents].to_f / instance[:number_of_rounds].to_f).round
    end

    discount_in_cents_with_shipping do |instance|
      next unless instance[:shipping_cost_in_cents] && instance[:discount_in_cents]
      discount = instance[:discount_in_cents] - instance[:shipping_cost_in_cents]
      discount > 0 ? discount : 0
    end

    discount_percent_with_shipping do |instance|
      next unless instance[:discount_in_cents_with_shipping] && instance[:current_price_in_cents]
      dp = (instance[:discount_in_cents_with_shipping].to_f / instance[:current_price_in_cents].to_f) * 100
      dp.to_i
    end
  end
end

