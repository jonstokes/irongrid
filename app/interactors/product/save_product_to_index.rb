class SaveProductToIndex
  include Interactor

  def call
    # Don't actually save the product to the index unless there was a UPC in the listing's product_source
    context.fail! unless should_write_product_to_index?
    context.product.save(prune_invalid_attributes: true)
  end

  def should_write_product_to_index?
    # Right now only listings that have a hard-captured product_upc can contribute product data
    # to the index. This condition may change to become more expansive, though.
    context.listing.product_source.upc.present?
  end
end

