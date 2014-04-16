desc "Fix zero length listing images" 
task :fix_images => :environment do
  Listing.find_each do |listing|
    next if CDN.has_image?(listing.image_source)
    listing.image = CDN::DEFAULT_IMAGE_URL
    listing.image_download_attempted = false
    listing.item_data_will_change!
    db { listing.update_record_without_timestamping }
  end
end
