class WriteProductToIndex
  class SaveProductToIndex
    include Interactor

    def call
      # Don't actually save the product to the index unless there was a UPC in the listing's product_source
      return unless should_write_product_to_index?
      context.product.save(prune_invalid_attributes: true)
      context.listing.product_source.id = context.product.id
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      Airbrake.notify(e)
      gong "Listing #{context.listing.url.page} raised #{e.message}"
    end

    def should_write_product_to_index?
      # Right now only listings that have a hard-captured product_upc can contribute product data
      # to the index. This condition may change to become more expansive, though.
      context.listing.product_source.upc.present?
    end
  end
end
