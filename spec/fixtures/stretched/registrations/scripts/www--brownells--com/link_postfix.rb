def avantlink_feed_link_postfix
  (Time.now - 1.day).strftime("%Y-%m-%d")
end

set "listing_url" do
  "#{json_adapter_output['url']}&from=#{avantlink_feed_link_postfix}"
end

