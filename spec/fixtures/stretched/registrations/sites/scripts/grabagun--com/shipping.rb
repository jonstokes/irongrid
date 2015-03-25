Stretched::Script.define "grabagun.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if product.guns?
        599
      end
    end
  end
end

