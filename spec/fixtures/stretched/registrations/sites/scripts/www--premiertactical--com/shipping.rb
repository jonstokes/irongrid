Stretched::Script.define "www.premiertactical.com/shipping" do
  # All ammo ships UPS ground
  # All handguns ship air freight
  # Long guns can ship ground
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      if current_price && (current_price > 20000)
        0
      end
    end
  end
end

