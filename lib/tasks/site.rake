namespace :site do
  desc "Create all sites from site manifest to redis"
  task :create_all => :environment do
    StretchedUtils.register_globals
    Site::CreateAll.call(
        directory: IronCore::Site.sites_dir,
        user:      Stretched::Settings.user,
    )
  end

  desc "Create all sites from site manifest to redis"
  task :add_new => :environment do
    StretchedUtils.register_globals
    Site::AddNew.call(
        directory: IronCore::Site.sites_dir,
        user:      Stretched::Settings.user,
    )
  end

  desc "Update site attributes without overwriting stats"
  task :update_all => :environment do
    StretchedUtils.register_globals
    Site::UpdateAll.call(
        directory: IronCore::Site.sites_dir,
        user:      Stretched::Settings.user,
    )
  end

  desc "Delete all listings for a site"
  task delete_all_listings: :environment do
    next unless domain = ENV['DOMAIN']
    query_hash = IronBase::Listing::Search.new(
        filters: {
            seller_domain: domain
        }
    ).query_hash

    puts "Deleting listings for #{domain} with query #{query_hash.inspect}"
    sleep 5
    IronBase::Listing.find_each(query_hash) do |batch|
      DeleteListingsWorker.perform_async(batch.map(&:id))
    end
  end

  task :flag_session_queues => :environment do
    IronCore::Site.each do |site|
      site.session_queue.flag!
    end
  end

  desc "Run stats for all active sites"
  task :stats => :environment do
    IronCore::Site.each do |site|
      SiteStatsWorker.perform_async(domain: site.domain) unless SiteStatsWorker.jobs_in_flight_with_domain(site.domain).any?
    end
  end

  desc "Remove deactivated sites"
  task :delete_dead => :environment do
    YAML.load_file("tmp/dead.yml").each do |domain|
      puts "Removing #{domain}"
      site = IronCore::Site.find(domain) rescue nil
      next unless site
      site.session_queue.clear
      site.listings_queue.clear
      site.product_links_queue.clear
      IronCore::Site.remove_domain(domain)
    end
  end

  desc "Jumpstart scrapes on sites with link_data"
  task :scrape_all => :environment do
    IronCore::Site.each do |site|
      if IronCore::LinkMessageQueue.new(domain: site.domain).any?
        PruneLinksWorker.perform_async(domain: site.domain)
      end
    end
  end

  desc "Roll back listing updates from a period of days"
  task :rollback_listing_updates => :environment do
    domains = %w(
      ammo.net
      bangitammo.com
      fgammo.com
      shop.qualitymadecartridges.com
      www.mimcammo.com
      www.brownells.com
      www.guncasket.com
      www.policestore.com
      www.sinclairintl.com
      www.sportsmanswarehouse.com
    )
    domains.each do |domain|
      puts "Rolling back #{domain}"
      Listing.where("seller_domain = ? AND updated_at > ?", domain, 16.hours.ago).find_each(:batch_size => 100) do |listing|
        puts "  Destroying listing #{listing.url}"
        listing.destroy
        listing.send(:update_es_index)
      end
      site = IronCore::Site.find(domain)
      puts "  Clearing listings queue of size #{site.listings_queue.size}"
      site.listings_queue.clear
    end
  end

  desc "Create site fixtures from local repo"
  task :generate_fixtures => :environment do
    domains = YAML.load_file("spec/fixtures/sites/manifest.yml")
    domains.each do |domain|
      site = IronCore::Site.find(domain, source: :local)
      filename = "spec/fixtures/sites/#{domain.gsub(".","--")}.yml"
      puts "Writing #{site.domain} to #{filename}"
      File.open(filename, "w") do |f|
        YAML.dump(site.site_data, f)
      end
    end
  end

end
