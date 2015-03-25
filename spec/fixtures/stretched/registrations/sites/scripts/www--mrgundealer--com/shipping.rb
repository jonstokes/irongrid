Stretched::Script.define "www.mrgundealer.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if product.guns?
        0
      else
        992
      end
    end
  end
end

