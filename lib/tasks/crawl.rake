task :crawl => :environment do
  crawler = Crawler.new("tmp/link_input.yml")
  crawler.crawl_links
  crawler.write_yaml
end

