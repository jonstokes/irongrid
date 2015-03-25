Stretched::Script.define "www.deansgunshop.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.guns?
        1999
      elsif product.ammunition?
        1500
      else
        1200
      end
    end
  end
end

