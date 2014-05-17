module ProductDetails::Metadata

  CATEGORY1_VALID_METADATA = {
    "Optics" => [:manufacturer],
    "Guns" => [:caliber, :manufacturer],
    "Ammunition" => [:caliber, :manufacturer, :grains, :number_of_rounds],
    "Accessories" => [:caliber, :manufacturer, :number_of_rounds],
    "None" => [:caliber, :manufacturer]
  }

  def self.attributes_to_be_extracted(category)
    if category == "None"
      CATEGORY1_VALID_METADATA["Ammunition"]
    else
      CATEGORY1_VALID_METADATA[category]
    end
  end
end
