class UpdateAndLinkProduct
  include Interactor::Organizer

  # This set of interactors begins with listing.product_source, and first tries to use
  # that data to update the Product index. It then uses the product index to populate
  # any missing product attributes for the listing, before writing a normalized product
  # to the listing object.

  organize [
    WriteProductToIndex,                 # Use this listing's product_source to update product index
    MatchProductByAttributes,            # If the listing's product_source didn't find or create a product, try best match
    IronBase::UpdateProductFromListing,  # Preserve captured product_source attrs in listing's product object
    LinkDenormalizedProduct              # Denormalize the product and assign it to the listing
  ]
end