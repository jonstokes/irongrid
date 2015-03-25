Stretched::Script.define "www.mrgundealer.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.guns?
        0
      else
        992
      end
    end
  end
end

