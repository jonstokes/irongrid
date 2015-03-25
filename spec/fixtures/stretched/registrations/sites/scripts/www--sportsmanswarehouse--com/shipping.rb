Stretched::Script.define "www.sportsmanswarehouse.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if current_price <= 2500
        595
      elsif current_price <= 5000
        895
      elsif current_price <= 7500
        1095
      elsif current_price <= 10000
        1295
      elsif current_price <= 15000
        1495
      elsif current_price <= 20000
        1695
      elsif current_price <= 30000
        1895
      elsif current_price > 30000
        1995
      end
    end
  end
end

