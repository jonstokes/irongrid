Stretched::Script.define "www.opticsplanet.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if current_price && (current_price > 4900)
        0
      end
    end
  end
end
