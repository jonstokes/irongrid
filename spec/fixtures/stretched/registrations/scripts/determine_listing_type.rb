set "type" do
  basic_type = json_adapter_output['type'].try(:capitalize) || adapter.default_listing_type.capitalize
  "#{basic_type}Listing"
end

