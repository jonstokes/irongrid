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
end

