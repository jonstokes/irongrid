class SetProductDetails
  include Interactor::Organizer

  organize [
    ProductDetails::IdentifyProduct,
  ]

end
