Stretched::Script.define do
  script "www.budsgunshop.com/script" do
    type "RetailListing"
    title do
      meta_title || meta_og_title || find_by_xpath(xpath: ".//title")
    end
    image { meta_og_image }
    sale_price_in_cents do |instance|
      if result = instance.sale_price_in_cents
        result.slice!("$")
        result.slice!(".")
        result.to_i
      end
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
