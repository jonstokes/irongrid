class SetProductDetails
  include Interactor::Organizer

  organize [
    ProductDetails::IdentifyProduct,
    ProductDetails::SoftCategorize
  ]

end
