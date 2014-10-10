Loadable::Script.define do
  script "www.budsgunshop.com/shipping_cost" do
    shipping_cost_in_cents do |instance|
      if instance[:category1] == "Guns"
        0
      elsif instance[:category1] == "Ammunition"
        995
      end
    end
  end
end
