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
    context.product.description ||= {
        long: context.product_json.long_description,
        short: context.product_json.short_description
    }
    IronBase::Product.properties.except(:weight, :image, :description).each do |attr|
      context.product[attr] ||= context.product_json[attr]
    end
    context.product.save
  end

end