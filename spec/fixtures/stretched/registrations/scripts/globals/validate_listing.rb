def auction_ended?
  context[:auction_ends].nil? || (auction_ends < Time.now)
end

def validation_string
  validation_type = type.split("Listing").first.downcase
  json_adapter_output['validation'][validation_type].gsub("raw", "json_adapter_output")
end

set "valid" do
  return false if type == "AuctionListing" && auction_ended?
  !!(eval validation_string)
end

