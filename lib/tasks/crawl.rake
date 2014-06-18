task :crawl => :environment do
  include PageUtils
  sources = YAML.load_file("tmp/link_input.yml")
  url_q = []
  final_url_list = Set.new
  sources["urls"].each { |url| url_q << url }

  while url = url_q.pop do
    puts "Crawling #{url}"
    next unless page = get_page(url)
    final_url_list << url
    page.doc.xpath(sources["follow_link_xpath"]).each do |node|
      url_q << "#{sources['follow_link_prefix']}#{node.text}" unless final_url_list.include?(url)
    end
  end

  final_feed_list = []
  final_url_list.each do |url|
    final_feed_list << {
      "url" => url,
      "product_link_xpath" => sources["product_link_xpath"]
    }
  end
  final_hash = {
    "feeds" => final_feed_list
  }
  File.open("tmp/link_sources.yml", "w") do |f|
    f.puts final_hash.to_yaml
  end
end

