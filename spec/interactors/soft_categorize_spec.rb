require 'spec_helper'

describe SoftCategorize do
  it "does nothing if the listing already has a hard category" do
    category1 = ElasticSearchObject.new(
      "category1",
      raw: "Optics",
      classification_type: "hard"
    )
    result = SoftCategorize.perform(
      category1: category1
    )
    expect(result.category1.raw).to eq("Optics")
    expect(result.category1.classification_type).to eq("hard")
  end

  it "metadata categorizes a listing if that's possible" do
    category1 = ElasticSearchObject.new(
      "category1",
      raw: "None",
      classification_type: "fall_through"
    )
    result = SoftCategorize.perform(
      category1: category1,
      grains: 10,
      caliber: "9mm Luger",
      number_of_rounds: 100
    )
    expect(result.category1.raw).to eq("Ammunition")
    expect(result.category1.classification_type).to eq("metadata")
  end

  it "soft categorizes a listing" do
    pending "Example"
  end

  it "applies a fall-through category of None" do
    pending "Example"
  end
end
