Stretched::Script.define "www.schuylerarmsco.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.ammunition?
        900
      else
        700
      end
    end
  end
end

