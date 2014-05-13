module UpdateImage
  def update_image(scraper)
    return unless image_source = scraper.listing["item_data"]["image_source"]
    if CDN.has_image?(image_source)
      scraper.listing["item_data"]["image_download_attempted"] = true
      scraper.listing["item_data"]["image"] = CDN.url_for_image(image_source)
    else
      scraper.listing["item_data"]["image"] = CDN::DEFAULT_IMAGE_URL
      @image_store.push image_source
      record_incr(:images_added)
    end
  end
end
