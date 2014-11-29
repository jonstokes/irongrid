class WriteProductToIndex
  include Interactor::Organizer

  organize [
     FindOrCreateProduct,
     UpdateProductImage,
     WriteProductToIndex
  ]
end