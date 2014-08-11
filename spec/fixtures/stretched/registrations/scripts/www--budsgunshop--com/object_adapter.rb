attribute "listing_type" do
  "RetailListing"
end

attribute "listing_location" do
  "1105 Industry Road Lexington, KY 40505"
end

attribute "listing_title" do
  meta_title ||
    meta_og_title ||
    find_by_xpath(xpath: ".//title")
end

attribute "listing_image" do
  meta_og_image ||
    filter(find_by_xpath(xpath: './/div[@style="padding:0px 8px 2px 8px;"]//img/@src', pattern: /images\/.*jpg/), [prefix: "http://www.budsgunshop.com/catalog/"]
end
