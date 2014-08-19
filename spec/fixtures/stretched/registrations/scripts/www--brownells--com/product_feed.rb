Stretched::Script.define do
  script "www.brownells.com/product_feed" do
    listing_url do
      "#{json_adapter_output['url']}&from=#{avantlink_feed_link_postfix}"
    end
  end
end
