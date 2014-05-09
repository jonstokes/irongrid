class SoftCategorize
  include Interactor

  def perform
    if es_objects[:category1]["classification_type"] == "fall_through"
      es_objects[:category1] = metadata_categorize ||
        soft_categorize("category1") ||
        {"category1" => "None", "classification_type" => "fall_through"}
    end
  end

  def soft_categorize(cat)
    return unless scrubbed[:title]
    SoftCategorizer.new(
      category_name: cat,
      price:         current_price_in_cents,
      title:         metadata_source_attributes['title']['scrubbed']
    ).categorize
  end
end
