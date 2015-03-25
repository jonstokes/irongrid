Stretched::Script.define "www.lg-outdoors.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if message1
        0
      end
    end
  end
end

