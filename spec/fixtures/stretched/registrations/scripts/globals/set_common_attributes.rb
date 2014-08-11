def hard_categorize(cat)
  return unless value = json_adapter_output[cat]
  {
    cat => value,
    "classification_type" => "hard"
  }
end

def default_categorize(cat)
  return unless value = adapter.send("default_#{cat}")
  {
    cat => value,
    "classification_type" => "default"
  }
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

set "title" do
  { "title" => json_adapter_output['title'] }
end

set "keywords" do
  return unless json_adapter_output['keywords']
  { "keywords" => json_adapter_output['keywords'] }
end

set "seller_domain" do
  site.domain
end

set "seller_name" do
  site.name
end

set "affiliate_link_tag" do
  site.affiliate_link_tag
end

set "affiliate_program" do
  site.affiliate_program
end

set "image" do
  return unless json_adapter_output['image']
  return unless clean_image = clean_up_image_url(json_adapter_output['image'])
  return unless is_valid_image_url?(clean_image)
  clean_image
end

set "item_condition" do
  if ['New', 'Used'].include? json_adapter_output['item_condition']
    json_adapter_output['item_condition']
  else
    adapter.default_item_condition.try(:titleize) || "Unknown"
  end
end

set "item_location" do
  return json_adapter_output['item_location'] if json_adapter_output['item_location'].present?
  adapter.default_item_location
end

set "auction_ends" do
  return unless type == "AuctionListing"
  ListingFormat.time(site: site, time: json_adapter_output['auction_ends'])
end

set "category1" do
  hard_categorize("category1") ||
    default_categorize("category1") ||
    {
      "category1" => "None",
      "classification_type" => "fall_through"
    }
end

