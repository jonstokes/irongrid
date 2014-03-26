def load_listing_source(type, seller, item)
  url = html = nil
  pt = create_parser_test(item)
  create_site_from_repo(seller)
  url = pt.url
  html = open(pt.html_on_s3).read
  { :url => url, :html => html }
end

def pages_from_parser_tests(opts)
  ParserTest.where(opts[:conditions]).limit(opts[:limit]).map do |pt|
    {
      url: pt.url,
      domain: pt.seller_domain,
      html: open(pt.html_on_s3).read
    }
  end
end

def create_scraper_double(new_attrs)
  new_page = double()
  new_page.stub("listing") { new_attrs }
  new_page.stub("image") { new_attrs["image"] }
  new_page.stub("full_image_url") { "http://rspec.com/foobar.jpg" }
  new_page.stub("cdn_name") { get_cdn_name(new_page.full_image_url) }
  new_page.stub("cdn_image_url") { get_cdn_image_url(new_page.cdn_name) }
  new_page.stub("url") { new_attrs["url"] }
  new_page
end

def create_parser_tests
  YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/manifest.yml").each do |filename|
    attrs = YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/#{filename}.yml").attributes
    attrs.delete("id")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    ParserTest.create(attrs)
  end
end

def create_parser_test(title)
  pt = nil
  YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/manifest.yml").each do |filename|
    next if pt
    attrs = YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/#{filename}.yml").attributes
    if attrs["title"] == title
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      pt = ParserTest.create(attrs)
    end
  end
  pt
end

def create_site_from_repo(domain)
  site = Site.new(domain: domain, source: :local)
  site.send(:write_to_redis)
  site
end

def create_sites
  YAML.load_file("#{Rails.root}/spec/fixtures/sites/manifest.yml").each do |domain|
    Site.new(domain: domain, source: :fixture).send(:write_to_redis)
  end
end
