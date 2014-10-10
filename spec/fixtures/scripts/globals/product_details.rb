Loadable::Script.define do
  script "globals/product_details" do
    price_per_round_in_cents do |instance|
      next instance[:price_per_round_in_cents] if instance[:price_per_round_in_cents]
      next nil unless (instance[:category1] == "Ammunition") &&
        instance[:current_price_in_cents] && instance[:number_of_rounds]
      (instance[:current_price_in_cents].to_f / instance[:number_of_rounds].raw.to_f).round rescue nil
    end
  end
end
