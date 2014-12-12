Loadable::Script.define do
  script "www.budsgunshop.com/shipping_cost" do
    shipping_cost do |instance|
      instance.listing.shipping ||= {}
      if instance.listing.gun?
        instance.listing.shipping.cost = 0
      elsif instance.listing.ammo?
        instance.listing.shipping.cost = 995
      end
    end
  end
end
