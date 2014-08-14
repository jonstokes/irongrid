Stretched::Script.define do
  script "www.budsgunshop.com/invalid_script" do
    listing_type "RetailListing"
    title do
      meta_title || meta_og_title || find_by_xpath(xpath: ".//title")
    end
    location "1105 Industry Road Lexington, KY 40505"
    image { meta_og_image }
    sale_price_in_cents do
      find_by_xpath(
        xpath: './/tr[@id="x2d"]/td[2]/div[1]/div[1]/div[2]/strong',
        pattern: /^\$\d[\d\,\.]+/i
      )
    end
    product_caliber do
      result = find_by_xpath(
        xpath: ".//div[@id='mainmain']//td[@class='main']/center/table//tr",
        pattern: /caliber\W*.*$/i
      )
      filters(result, [{reject: /caliber/i}])
    end
  end
end
