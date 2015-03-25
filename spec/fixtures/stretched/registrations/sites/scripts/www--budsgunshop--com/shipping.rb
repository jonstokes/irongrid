Stretched::Script.define "www.budsgunshop.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
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
