module ProductDetails
  class IdentifyProduct
    include Interactor

    def call
      return if context.product = find_by_upc
      context.products = mpn_products || sku_products
    end

    def find_by_upc
      return unless context.listing_json.product_upc.present?
      IronBase::Product.find_by_upc(context.listing_json.product_upc)
    end

    def mpn_products
      return unless context.listing_json.product_mpn.present?
      mpn = IronBase::Product.normalize(context.listing_json.product_mpn)
      products = IronBase::Product.find_by_mpn(mpn)
      products.hits.any? ? products : nil
    end

    def sku_products
      return unless context.listing_json.product_sku.present?
      sku = IronBase::Product.normalize(context.listing_json.product_sku)
      products = IronBase::Product.find_by_sku(sku)
      products.hits.any? ? products : nil
    end

  end
end
