require 'spec_helper'

describe SetPricePerRound do
  it "calculates the current price per round" do
    result = SetPricePerRound.perform(
      current_price_in_cents: 100,
      number_of_rounds: ElasticSearchObject.new("number_of_rounds", raw: 10),
      category1: ElasticSearchObject.new("category1", raw: "Ammunition"),
      listing_json: Hashie::Mash.new
    )
    expect(result.price_per_round_in_cents).to eq(10)
  end
end
