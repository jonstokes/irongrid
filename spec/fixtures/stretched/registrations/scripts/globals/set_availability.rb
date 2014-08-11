def retail_availability
  if ["in_stock", "out_of_stock"].include? raw_listing['availability']
    raw_listing['availability']
  else
    adapter.default_availability || "unknown"
  end
end

set "availability" do
  if type == "RetailListing"
    retail_availability
  else
    "in_stock"
  end
end

