class SoftCategorize
  include Interactor

  def perform
    if category1.classification_type == "fall_through"
      context[:category1] = metadata_categorize ||
        soft_categorize("category1") ||
        ElasticSearchObject.new(
          "category1",
          raw:                  "None",
          classification_type: "fall_through"
        )
    end
  end

  def metadata_categorize
    return unless grains && number_of_rounds && caliber
      ElasticSearchObject.new(
        "category1",
        raw:                  "Ammunition",
        classification_type:  "metadata"
      )
  end

  def soft_categorize(cat)
    return unless scrubbed[:title]
    SoftCategorizer.new(
      category_name: cat,
      price:         current_price_in_cents,
      title:         title.scrubbed
    ).categorize
  end
end