class SaveProductToIndex
  include Interactor

  def call
    context.product.save
  end
end

