class MergeJsonIntoProduct
  include Interactor

  def call
    context.fail! if context.product.complete?
    context.product.mpn = context.product_json.mpn
    context.product.sku = context.product_json.sku
    context.product.weight ||= { shipping: context.product_json.weight }
    context.product.image ||= {
        source: context.product_json.image,
        cdn: context.image_cdn,
        download_attempted: !!context.image_download_attempted
    }
    context.product.shell_length ||= {
        inches: context.product_json.shell_length_in_inches,
        millimeters: context.product_json.shell_length_in_millimeters
    }
    IronBase::Product.properties.except(:mpn, :sku, :weight, :image, :shell_length).each do |attr|
      context.product[attr] ||= context.product_json[attr]
    end
    context.product.save
  end

end