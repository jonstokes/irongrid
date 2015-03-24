Stretched::Script.define "www.budsgunshop.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if product.guns?
        0
      elsif product.ammunition?
        995
      end
    end
  end
end