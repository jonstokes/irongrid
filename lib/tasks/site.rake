def copy_site(domain)
  puts "Copying site #{domain} from git to redis..."
  Site.new(domain: domain, source: :git).send(:write_to_redis)
end

namespace :site do
  desc "Copy all sites from github to redis"
  task :copy_all => :environment do
    YAML.load(Github.fetch_file_from_github("sites/site_manifest.yml")).each do |domain|
      copy_site(domain)
    end
  end

  desc "Copy a site from github to redis"
  task :copy => :environment do
    raise "Must set DOMAIN" unless domain = ENV['DOMAIN']
    copy_site(domain)
  end

  desc "Jumpstart scrapes on sites with link_data"
  task :scrape_all => :environment do
    Site.all.each do |site|
      if LinkQueue.new(domain: site.domain).any?
        PruneLinksWorker.perform_async(domain: site.domain)
      end
    end
  end
end
