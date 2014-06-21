task :avantlink_refresh => :environment do
  domains = %w(
    www.brownells.com
    www.guncasket.com
    www.policestore.com
    www.sinclairintl.com
    www.sportsmanswarehouse.com
  )

  domains.each do |domain|
    AvantlinkWorker.perform_async(domain)
  end
end
