Stretched::Script.define "www.zxgun.biz/shipping" do
  extensions 'globals/extensions/*'
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

