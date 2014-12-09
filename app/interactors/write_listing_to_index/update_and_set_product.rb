class UpdateAndSetProduct
  include Interactor::Organizer

  organize [
    UpdateProductIndexFromListingSource,
    MatchProductByAttributes,
    IronBase::ImportListingToProduct,
    SetProduct
  ]
end