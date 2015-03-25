Stretched::Script.define "grabagun.com/shipping" do
  extensions [
   'globals/extensions/*',
   'ironsights/extensions/irongrid/*'
 ]

  script do
    shipping_cost do
      if product.guns?
        599
      end
    end
  end
end

