namespace :site do

  task remove_inactive: :environment do
    inactive = SiteLibrary::Site.domains - SiteLibrary::Site.manifest
    inactive.each { |domain| SiteLibrary::Site.remove_domain(domain) }
  end

  desc "Create all sites from site manifest to redis"
  task :create_all => :environment do
    SiteLibrary::CreateAll.call
  end

  desc "Create all sites from site manifest to redis"
  task :add_new => :environment do
    SiteLibrary::AddNew.call
  end

  desc "Update site attributes without overwriting stats"
  task :update_all => :environment do
    SiteLibrary::UpdateAll.call
  end

  task :flag_session_queues => :environment do
    SiteLibrary::Site.each do |site|
      site.session_queue.flag!
    end
  end

  desc "Update affiliate urls"
  task update_affiliates: :environment do
    ['www.swva-arms.com', 'www.gunsinternational.com'].each do |domain|
      site = SiteLibrary::Site.find domain
      IronBase::Listing.find_each(query_hash(domain)) do |batch|
        batch.each do |listing|
          listing.url.purchase = to_affiliate_url(listing.url.purchase, site)
          listing.save
        end
      end
    end
  end

  def query_hash(domain)
    IronBase::Listing::Search.new(
        filters: {
            seller_domain: domain
        }
    ).query_hash
  end

  def to_affiliate_url(base_url, site)
    link = base_url.to_query('url')
    "#{site.affiliate_link_prefix}#{link}#{site.affiliate_link_tag}"
  end

  desc "Run stats for all active sites"
  task :stats => :environment do
    SiteLibrary::Site.each do |site|
      SiteStatsWorker.perform_async(domain: site.domain) unless SiteStatsWorker.jobs_in_flight_with_domain(site.domain).any?
    end
  end

  desc "Remove deactivated sites"
  task :delete_dead => :environment do
    YAML.load_file("tmp/dead.yml").each do |domain|
      puts "Removing #{domain}"
      site = SiteLibrary::Site.find(domain) rescue nil
      next unless site
      site.session_queue.clear
      site.listings_queue.clear
      site.product_links_queue.clear
      SiteLibrary::Site.remove_domain(domain)
    end
  end

  desc "Jumpstart scrapes on sites with link_data"
  task :scrape_all => :environment do
    SiteLibrary::Site.each do |site|
      if site.link_message_queue.any?
        RefreshLinksWorker.perform_async(domain: site.domain)
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
      site = SiteLibrary::Site.find(domain)
      puts "  Clearing listings queue of size #{site.listings_queue.size}"
      site.listings_queue.clear
    end
  end

  desc "Create site fixtures from local repo"
  task :generate_fixtures => :environment do
    domains = YAML.load_file("spec/fixtures/sites/manifest.yml")
    domains.each do |domain|
      site = SiteLibrary::Site.find(domain, source: :local)
      filename = "spec/fixtures/sites/#{domain.gsub(".","--")}.yml"
      puts "Writing #{site.domain} to #{filename}"
      File.open(filename, "w") do |f|
        YAML.dump(site.site_data, f)
      end
    end
  end

end
