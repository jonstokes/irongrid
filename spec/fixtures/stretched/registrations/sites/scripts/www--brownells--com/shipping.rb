Stretched::Script.define "www.brownells.com/shipping" do
  extensions [
     'globals/extensions/*',
     'ironsights/extensions/irongrid/*'
  ]
  script do
    shipping_cost do
      if product.ammunition?
        1595
      end
    end
  end
end
