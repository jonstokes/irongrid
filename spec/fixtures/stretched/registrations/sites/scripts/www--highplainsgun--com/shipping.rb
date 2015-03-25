Stretched::Script.define "www.highplainsgun.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if current_price > 19900
        0
      else
        900
      end
    end
  end
end
