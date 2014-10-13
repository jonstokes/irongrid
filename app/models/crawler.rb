class Crawler
  include Sunbro

  %w(
    product_link_xpath
    product_link_prefix
    catalog_link_postfix
    follow_link_prefix
    follow_link_xpaths
    urls
  ).each do |key|
    define_method key do
      @sources[key]
    end
  end

  def initialize(filename)
    @sources = YAML.load_file(filename)
    @visited = Set.new
    @final_url_set = Set.new
    @url_q = @sources["urls"].uniq
  end

  def write_yaml
    feed_hash = { "feeds" => feeds }
    File.open("tmp/link_sources.yml", "w") do |f|
      f.puts feed_hash.to_yaml
    end
  end

  def feeds
    @final_url_set.map do |url|
      {
        "url" => "#{url}#{catalog_link_postfix}",
        "product_link_xpath" => product_link_xpath,
        "product_link_prefix" => product_link_prefix
      }
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

  def extract_links(page)
    follow_link_xpaths.each do |xpath|
      page.doc.xpath(xpath).each do |node|
        url = "#{follow_link_prefix}#{node.text.strip}"
        @url_q << url unless visited?(url)
      end
    end
  end

  def visited?(url)
    @visited.include?(url)
  end

  def visit(url)
    @visited << url
    get_page(url)
  end

  def is_product_page?(page)
    page.doc.xpath(product_link_xpath).any?
  end
end
