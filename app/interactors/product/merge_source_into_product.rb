class MergeSourceIntoProduct
  include Interactor
  include ObjectMapper

  def call
    context.product.import_from_listing!(context.listing)
  end

end