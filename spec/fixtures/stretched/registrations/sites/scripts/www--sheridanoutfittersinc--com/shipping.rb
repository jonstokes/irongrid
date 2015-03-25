Stretched::Script.define "www.sheridanoutfittersinc.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.ammunition?
        1000
      elsif product.guns?
        2500
      else
        1250
      end
    end
  end
end
