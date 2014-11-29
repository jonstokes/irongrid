class UpdateProductImage
  include Interactor

  def call
    return unless image_source = context.product_json.image_source
    context.product.image ||= {}
    if CDN.has_image?(image_source)
      context.product.image.merge!(
          cdn: CDN.url_for_image(image_source),
          download_attempted: true
      )
    else
      context.product.image.merge!(cdn: CDN::DEFAULT_IMAGE_URL)
      ImageQueue.new(domain: context.site.domain).push image_source
    end
  end
end