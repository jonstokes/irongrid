Loadable::Script.define do
  script "www.budsgunshop.com/shipping_cost" do
    shipping_cost do
      if listing.gun?
        0
      elsif listing.ammo?
        995
      end
    end
  end
end
