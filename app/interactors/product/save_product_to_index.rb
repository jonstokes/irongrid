class SaveProductToIndex
  include Interactor

  def call
    context.product.save(prune_invalid_attributes: true)
  end
end

