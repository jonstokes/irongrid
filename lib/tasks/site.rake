namespace :site do
  desc "Copy all sites from github to redis"
  task :copy_all => :environment do
    include Github
    YAML.load(fetch_file_from_github("sites/site_manifest.yml")).each do |domain|
      copy_site(domain)
    end
  end

  desc "Copy a site from the local repo to redis"
  task :copy => :environment do
    raise "Must set DOMAIN" unless domain = ENV['DOMAIN']
    Site.create_site_from_local(domain)
  end

  desc "Run stats for all active sites"
  task :stats => :environment do
    Site.all.each do |site|
      SiteStatsWorker.perform_async(domain: site.domain) unless SiteStatsWorker.jobs_in_flight_with_domain(site.domain).any?
    end
  end

  desc "Update site attributes without overwriting stats"
  task :update_all => :environment do
    Site.all.each do |site|
      Site.update_site_from_local(site)
    end
  end

  desc "Add new sites from site manifest to redis"
  task :add_new => :environment do
    domains = YAML.load_file("../ironsights-sites/sites/site_manifest.yml")
    Site.add_domains(domains)
  end

  desc "Remove deactivated sites"
  task :delete_dead => :environment do
    YAML.load_file("tmp/dead.yml").each do |domain|
      puts "Removing #{domain}"
      site = Site.new(domain: domain) rescue nil
      next unless site
      site.session_queue.clear
      site.listings_queue.clear
      site.product_links_queue.clear
      Site.remove_domain(domain)
    end
  end

  desc "Jumpstart scrapes on sites with link_data"
  task :scrape_all => :environment do
    Site.all.each do |site|
      if LinkMessageQueue.new(domain: site.domain).any?
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
      site = Site.new(domain: domain)
      puts "  Clearing listings queue of size #{site.listings_queue.size}"
      site.listings_queue.clear
    end
  end

  desc "Re-run product feeds"
  task :rerun_product_feeds => :environment do
    domains = %w(
      ammo.net
      fgammo.com
      shop.qualitymadecartridges.com
      www.brownells.com
      www.guncasket.com
      www.policestore.com
      www.sinclairintl.com
      www.sportsmanswarehouse.com
    )
    domains.each do |domain|
      puts "Rerunning product feed for #{domain}..."
      ProductFeedWorker.new.perform(domain: domain)
    end
  end

  desc "Create site fixtures from local repo"
  task :generate_fixtures => :environment do
    domains = YAML.load_file("spec/fixtures/sites/manifest.yml")
    domains.each do |domain|
      site = Site.new(domain: domain, source: :local)
      filename = "spec/fixtures/sites/#{domain.gsub(".","--")}.yml"
      puts "Writing #{site.domain} to #{filename}"
      File.open(filename, "w") do |f|
        YAML.dump(site.site_data, f)
      end
    end
  end

  def fix_site(domain)
    puts "Fixing #{domain}"
    legacy_site = LegacySite.new(domain: domain, source: :local)
    site = Site.new(domain: domain, source: :local)
    next unless site.site_data[:registrations]['object_adapter']["#{domain}/product_link"]
    filters = {
      'filters' => [ 'prefix' => legacy_site.link_prefix  ]
    }
    site.site_data[:registrations]['object_adapter']["#{domain}/product_link"]['attribute']['product_link'].each do |setter|
      setter.merge!(filters) if legacy_site.link_prefix
    end
    site.write_yaml
  end

  task :restore_prefixes => :environment do
    domains = YAML.load_file("../sites/site_manifest.yml")
    domains.each do |domain|
      fix_site(domain) rescue next
    end

    domains = YAML.load_file("#{Figaro.env.sites_repo}/sites/site_manifest.yml")
    domains.each do |domain|
      fix_site(domain) rescue next
    end
  end

end
