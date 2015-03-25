Stretched::Script.define "www.sfarmoryinc.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if product.ammunition?
        995
      elsif product.guns?
        1995
      else
        795
      end
    end
  end
end
