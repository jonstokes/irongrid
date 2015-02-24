Loadable::Script.define do
  script "www.budsgunshop.com/shipping" do
    shipping_cost do
      if product.guns?
        0
      elsif product.ammunition?
        995
      end
    end
  end
end
