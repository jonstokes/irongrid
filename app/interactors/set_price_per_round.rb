class SetPricePerRound
  include Interactor

  def perform
    context[:price_per_round_in_cents] = listing_json.price_per_round_in_cents || price_per_round_in_cents
  end

  def price_per_round_in_cents
    return unless (category1.raw == "Ammunition") && current_price_in_cents && context[:number_of_rounds]
    (current_price_in_cents.to_f / number_of_rounds.raw.to_f).round
  rescue
    Rails.logger.info "Price per round failed for #{url} with title #{title}"
    0
  end
end
