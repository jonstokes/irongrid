class SetPricePerRound
  include Interactor

  def perform
    context[:item_data]['price_per_round_in_cents'] = price_per_round_in_cents
  end

  def price_per_round_in_cents
    return unless current_price_in_cents && number_of_rounds
    (current_price_in_cents.to_f / number_of_rounds.to_f).round
  rescue
    Rails.logger.info "Price per round failed for #{url} with title #{title}"
    0
  end
end
