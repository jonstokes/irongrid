Loadable::Script.define do
  script "www.budsgunshop.com/shipping_cost" do
    shipping_cost do |instance|
      if instance.listing.product.category1 == "Guns"
        instance.listing.shipping_cost = 0
      elsif instance.listing.product.category1 == "Ammunition"
        instance.listing.shipping_cost = 995
      end
    end
  end
end
