set "price_per_round_in_cents" do
  return unless (category["category1"] == "Ammunition") && current_price_in_cents && context[:number_of_rounds]
  (current_price_in_cents.to_f / number_of_rounds.raw.to_f).round rescue 0
end
