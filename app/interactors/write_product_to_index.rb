class WriteProductToIndex
  include Interactor::Organizer

  # Expects *product_json* always
  # Expects *site* if the image pipeline is needed
  # Can also take *image_cdn* and *image_download_attempted*

  organize [
     FindOrCreateProduct,
     IronBase::UpdateProductFromListing,
     UpdateProductImage,
     SaveProductToIndex
  ]
end