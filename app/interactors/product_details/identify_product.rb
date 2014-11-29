module ProductDetails
  class IdentifyProduct
    include Interactor

    def call
      return if upc && context.product = IronBase::Product.find_by_upc(upc)
      mpn_products = IronBase::Product.find_by_mpn(mpn)
      return context.products = mpn_products if mpn_products.hits.any?
      sku_products = IronBase::Product.find_by_sku(sku)
      context.products = sku_products if sku_products.any?
    end

    def upc
      context.listing_json.product_upc
    end

    def mpn
      return unless arg = context.listing_json.product_mpn
      IronBase::Product.normalize(arg)
    end

    def sku
      return unless arg = context.listing_json.product_sku
      IronBase::Product.normalize(arg)
    end

  end
end
