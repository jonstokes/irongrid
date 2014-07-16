namespace :cleanup do
  task :auctions => :environment do
    count = 0
    Listing.where("type = ?", "AuctionListing").find_each do |listing|
      next if listing.auction_ends
      listing.destroy
      listing.update_index
      count += 1
      puts "Destroyed #{count} auctions" if (count % 500) == 0
    end
  end

  task :listings => :environment do
    Listing.record_timestamps = false
    count = 0
    Listing.find_each do |listing|
      listing.seller_domain = listing.item_data["seller_domain"]
      listing.image = listing.item_data["image"]
      listing.image_download_attempted = listing.item_data["image_download_attempted"]
      listing.auction_ends = listing.item_data["auction_ends"]
      listing.save!
      count += 1
      puts "Migrated #{count} listings" if (count % 500) == 0
    end
    Listing.record_timestamps = true
  end
end

