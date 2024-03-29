Stretched::Script.define "www.midwayusa.com/shipping" do
  extensions [
       'globals/extensions/*',
       'ironsights/extensions/irongrid/*'
   ]
  script do
    shipping_cost do
      ships_free = !!message1
      dot = !!message2
      if ships_free && current_price && (current_price >= 2500)
        0
      elsif weight
        ship_weight = weight.to_f.ceil
        if dot
          if weight < 1.0
            899
          elsif weight < 10.1
            899 + (ship_weight * 60)
          else
            999 + ship_weight * 20
          end
        else
          if weight < 1.0
            399
          elsif weight < 10.1
            599 + (ship_weight * 60)
          else
            999 + ship_weight * 20
          end
        end
      end
    end
  end
end
