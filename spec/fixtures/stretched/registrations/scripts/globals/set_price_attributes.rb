set "buy_now_price_in_cents" do
  ListingFormat.price(json_adapter_output['buy_now_price_in_cents'])
end

set "current_bid_in_cents" do
  ListingFormat.price(json_adapter_output['current_bid_in_cents'])
end

set "minimum_bid_in_cents" do
  ListingFormat.price(json_adapter_output['minimum_bid_in_cents'])
end

set "reserve_in_cents" do
  ListingFormat.price(json_adapter_output['reserve_in_cents'])
end

set "price_in_cents" do
  ListingFormat.price(json_adapter_output['price_in_cents'])
end

set "sale_price_in_cents" do
  ListingFormat.price(json_adapter_output['sale_price_in_cents'])
end

set "price_on_request" do
  json_adapter_output['price_on_request']
end
