Loadable::Script.define do
  script 'www.budsgunshop.com/shipping_cost' do
    shipping_cost do |instance|
      if instance.listing.gun?
        instance.listing.shipping_cost = 0
      elsif instance.listing.ammo?
        instance.listing.shipping_cost = 995
      end
    end
  end
end
