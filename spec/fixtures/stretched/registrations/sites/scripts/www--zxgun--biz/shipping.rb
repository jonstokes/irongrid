Stretched::Script.define "www.zxgun.biz/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if product.guns?
        2000
      else
        1200
      end
    end
  end
end

