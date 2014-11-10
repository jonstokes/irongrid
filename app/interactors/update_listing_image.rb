class UpdateListingImage
  include Interactor

  def call
    return unless image_source = listing.image.try(:source)
    listing.image ||= {}
    if CDN.has_image?(image_source)
      listing.image.merge!(
          cdn: CDN.url_for_image(image_source),
          download_attempted: true
      )
    else
      listing.image.merge!(cdn: CDN::DEFAULT_IMAGE_URL)
      ImageQueue.new(domain: context.site.domain).push image_source
    end
  end

  def listing
    context.listing
  end
end