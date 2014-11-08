class SaveListingToIndex
  include Interactor

  def call
    update_image
    context.listing.save
  end

  def update_image
    return unless image_source = listing.image.source
    if CDN.has_image?(image_source)
      listing.image.download_attempted = true
      listing.image.cdn = CDN.url_for_image(image_source)
    else
      listing.image.cdn = CDN::DEFAULT_IMAGE_URL
      ImageQueue.new(domain: context.site.domain).push image_source
    end
  end

  def listing
    context.listing
  end
end

