Stretched::Script.define "www.hoosierarmory.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if product.guns?
        1495
      elsif product.ammunition?
        995
      else
        1395
      end
    end
  end
end

