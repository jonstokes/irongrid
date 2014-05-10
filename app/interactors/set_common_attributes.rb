class SetCommonAttributes
  include Interactor

  def perform
    context[:item_data] = {
      'category1' => category1,
      'description' => description,
      'image_source' => image_source,
      'image_download_attempted' => false,
      'item_condition' => item_condition,
      'item_location' => item_location
    }
  end

  def category1
    hard_categorize("category1") ||
      default_categorize("category1") ||
      {"category1" => "None", "classification_type" => "fall_through"}
  end

  def description
    raw_listing['description']
  end

  def image_source
    return unless @raw_listing['image']
    return unless image_source = clean_up_image_url(@raw_listing['image'])
    unless is_valid_image_url?(image_source)
      notify "## IMAGE ERROR at #{url}. Image source is #{image_source}"
      return nil
    end
    image_source
  end

  def image_download_attempted
    false
  end

  def item_condition
    if ['New', 'Used'].include? raw_listing['item_condition']
      raw_listing['item_condition']
    else
      adapter.default_condition.try(:titleize) || "Unknown"
    end
  end

  def item_location
    return raw_listing['item_location'] if raw_listing['item_location'].present?
    adapter.default_item_location
  end

  def hard_categorize(cat)
    return unless value = raw_listing[cat]
    { cat => value, "classification_type" => "hard" }
  end

  def default_categorize(cat)
    return unless value = adapter.send("default_#{cat}")
    { cat => value, "classification_type" => "default" }
  end
end
