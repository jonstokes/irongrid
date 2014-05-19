class SetCommonAttributes < CoreModel
  include Interactor

  def perform
    context[:title] = title
    context[:keywords] = keywords
    context[:category1] = category1

    context[:seller_domain] = site.domain
    context[:seller_name] = site.name
    context[:affiliate_link_tag] = site.affiliate_link_tag
    context[:description] =  description
    context[:image_source] = image_source
    context[:image_download_attempted] = false
    context[:item_condition] = item_condition
    context[:item_location] = item_location
  end

  def title
    ElasticSearchObject.new("title", raw: raw_listing['title'])
  end

  def keywords
    ElasticSearchObject.new("keywords", raw: raw_listing['keywords'])
  end

  def category1
    hard_categorize("category1") ||
      default_categorize("category1") ||
      ElasticSearchObject.new(
        "category1",
        raw:                  "None",
        classification_type: "fall_through"
      )
  end

  def description
    raw_listing['description']
  end

  def image_source
    return unless raw_listing['image']
    return unless image_source = clean_up_image_url(raw_listing['image'])
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
    ElasticSearchObject.new(
      cat,
      raw: value,
      classification_type: "hard"
    )
  end

  def default_categorize(cat)
    return unless value = adapter.send("default_#{cat}")
    ElasticSearchObject.new(
      cat,
      raw: value,
      classification_type: "default"
    )
  end

  def clean_up_image_url(link)
    return unless retval = URI.encode(link)
    return retval unless retval["?"]
    retval.split("?").first
  end

  def is_valid_image_url?(link)
    return false unless is_valid_url?(link)
    extensions = %w(.png .jpg .jpeg .gif .bmp)
    extensions.select { |ext| link.downcase[ext] }.any?
  end

  def is_valid_url?(link)
    begin
      uri = URI.parse(link)
      %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      return false
    rescue URI::InvalidURIError
      return false
    end
  end
end
