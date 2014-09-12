Script.define do
  script "www.budsgunshop.com/shipping" do
    shipping_cost_in_cents do |instance|
      if instance.product_category1 == "Guns"
        0
      end
    end
  end
end
