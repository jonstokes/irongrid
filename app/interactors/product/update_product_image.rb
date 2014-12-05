class UpdateProductImage
  include Interactor

  before do
    context.product.image ||= {}
  end

  def call
    return if context.site.nil? || context.product.image.download_attempted
    return unless image_source = context.product.image.source
    if CDN.has_image?(image_source)
      context.product.image.merge!(
          cdn: CDN.url_for_image(image_source),
          download_attempted: true
      )
    else
      context.product.image.merge!(cdn: CDN::DEFAULT_IMAGE_URL)
      context.site.image_queue.push image_source
    end
  end
end