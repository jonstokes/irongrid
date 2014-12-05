module ProductDetails
  class SetProductDetails
    include Interactor

    before do
      context.listing.product_source = context.listing.product.dup
    end

    def call
      return unless context.product
      context.listing.product = context.product.merge(context.listing.product)
    end

  end
end
