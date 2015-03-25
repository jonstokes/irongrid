Stretched::Script.define "www.hyattgunstore.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if current_price && product.category1
        if product.guns?
          2998
        elsif product.ammunition?
          1999
        elsif current_price <= 1899
          984
        elsif current_price < 3599
          999
        elsif (current_price < 20000) && (product.category1 != "Optics")
          1499
        elsif product.category1 != "Optics"
          1699
        end
      end
    end
  end
end

