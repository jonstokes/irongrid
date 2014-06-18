def sources
  @sources
end

def visited?(url)
  @visited.include?(url)
end

def visit(url)
  @visited << url
  get_page(url)
end

def initialize_sets
  @sources = YAML.load_file("tmp/link_input.yml")
  @visited = Set.new
  @final_url_set = Set.new
  @url_q = sources["urls"].uniq
end

def is_product_page?(page)
  page.doc.xpath(sources["product_link_xpath"]).any?
end

def extract_links(page)
  page.doc.xpath(sources["follow_link_xpath"]).each do |node|
    url = "#{sources['follow_link_prefix']}#{node.text}"
    @url_q << url unless visited?(url)
  end
end

def crawl_links
  while url = @url_q.pop do
    puts "Crawling #{url}"
    next unless page = visit(url)
    @final_url_set << url if is_product_page?(page)
    extract_links(page)
  end
end

def feeds
  @final_url_set.map do |url|
    {
      "url" => url,
      "product_link_xpath" => sources["product_link_xpath"]
    }
  end
end

def write_yaml
  feed_hash = { "feeds" => feeds }
  File.open("tmp/link_sources.yml", "w") do |f|
    f.puts feed_hash.to_yaml
  end
end

task :crawl => :environment do
  include PageUtils
  initialize_sets
  crawl_links
  write_yaml
end

