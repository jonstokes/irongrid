task :avantlink_refresh => :environment do
  domains = %w(
    www.brownells.com
    www.guncasket.com
    www.policestore.com
    www.sinclairintl.com
    www.sportsmanswarehouse.com
  )

  domains.each do |domain|
    AvantlinkWorker.perform_async(domain: domain)
  end

  domains.each do |domain|
    Listing.where("item_data->>'seller_domain' = ? AND updated_at < ?", domain, 1.day.ago).find_each do |listing|
      listing.destroy
    end
  end
end
