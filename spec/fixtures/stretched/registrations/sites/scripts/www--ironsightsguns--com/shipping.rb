Stretched::Script.define "www.ironsightsguns.com/shipping"do
  extensions 'globals/extensions/*'
  script  do
    shipping_cost do
      if product.guns?
        4500
      elsif
        product.ammunition?
        4000
      else
        2500
      end
    end
  end
end
