Stretched::Script.define "www.hitekestore.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.guns?
        2500
      elsif product.ammunition?
        2500
      else
        1250
      end
    end
  end
end

