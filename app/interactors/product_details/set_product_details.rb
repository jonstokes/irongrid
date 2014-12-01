module ProductDetails
  class SetProductDetails
    include Interactor

    def call
      return unless context.product
      context.listing.product ||= {}
      context.listing.product = context.product.merge(context.listing.product)
    end

  end
end
