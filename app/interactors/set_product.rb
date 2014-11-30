class SetProduct
  include Interactor::Organizer

  organize [
    ProductDetails::IdentifyProduct,
    ProductDetails::SetProductDetails
  ]

end
