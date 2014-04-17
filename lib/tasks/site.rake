def copy_site(domain)
  puts "Copying site #{domain} from git to redis..."
  Site.new(domain: domain, source: :git).send(:write_to_redis)
end

namespace :site do
  desc "Copy all sites from github to redis"
  task :copy_all => :environment do
    include Github
    YAML.load(fetch_file_from_github("sites/site_manifest.yml")).each do |domain|
      copy_site(domain)
    end
  end

  desc "Copy a site from github to redis"
  task :copy => :environment do
    raise "Must set DOMAIN" unless domain = ENV['DOMAIN']
    copy_site(domain)
  end

  desc "Run stats for all active sites"
  task :stats => :environment do
    Site.active.each do |site|
      SiteStatsWorker.perform_async(domain: site.domain) unless SiteStatsWorker.jobs_in_flight_with_domain(site.domain).any?
    end
  end

  desc "Update site attributes without overwriting stats"
  task :update_all => :environment do
    Site.active.each do |site|
      gh_site = Site.new(domain: site.domain, source: :git)
      Site::SITE_ATTRIBUTES.each do |attr|
        next if [:read_at, :stats].include?(attr)
        site.site_data[attr] = gh_site.site_data[attr]
      end
      site.send(:write_to_redis)
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
end
