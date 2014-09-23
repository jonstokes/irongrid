RSpec.configure do |config|
  config.before :each do
    if example.metadata[:parser_tests] == true
      create_parser_tests
    end
  end
end


def load_listing_source(type, seller, item)
  url = html = nil
  pt = create_parser_test(item)
  create_site(seller)
  url = pt.source_url
  html = open(pt.html_on_s3).read

  File.open("tmp/#{pt.id}.html", "wb") do |f|
    puts "Writing #{type} #{seller} #{item} to #{pt.id}.html"
    f.write html
  end

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
    pt_title = attrs['listing_data']['item_data']['title'].detect {|h| h['title']}['title'] rescue nil
    if pt_title == title
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      pt = ParserTest.create(attrs)
    end
  end
  pt
end
