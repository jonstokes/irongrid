class CleanUpCommonListingAttributes
  include Interactor

  def perform
    context[:item_data] = {
      'category1' => category1,
      'description' => description,
      'availability' => availability,
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
    @description ||= raw_listing['description']
  end

  def availability
    stock_status.parameterize("_")
  end

  def image_source
    return nil unless @raw_listing['image']
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
      return raw_listing['item_condition']
    elsif raw_listing['condition_new']
      return "New"
    elsif raw_listing['condition_used']
      return "Used"
    else
      adapter.default_condition.try(:titleize) || "Unknown"
    end
  end

  def item_location
    @item_location ||= begin
      loc = raw_listing['item_location']
      loc && !loc.blank? ? loc : adapter.default_item_location
    end
  end

  def hard_categorize(cat)
    return unless value = raw_listing[cat]
    { cat => value, "classification_type" => "hard" }
  end

  def default_categorize(cat)
    return unless value = adapter.send("default_#{cat}")
    { cat => value, "classification_type" => "default" }
  endß
end
