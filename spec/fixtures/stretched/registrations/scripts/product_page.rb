Stretched::Script.define do
  script "globals/product_page" do
    title "This is the title"
    description "This is the description"
    price { context[:price] + 50 }
    sale_price { |instance| instance[:price] - 10 }
  end
end
