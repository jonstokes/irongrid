class SaveListingToIndex
  include Interactor

  def call
    context.listing.save
  end
end

