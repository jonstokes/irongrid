def check_presence(pt)
  if pt.scraper.nil?
    pt.scrape_errors << { pt: "not_found: #{pt.not_found}", page: "#{not_found}: true" } if !pt.not_found?
    return false
  end
  true
end

def check_statuses(pt)
  %w(is_valid? not_found?).each do |attr|
    if pt.send(attr) != pt.scraper.send(attr)
      pt.scrape_errors << { pt: "#{attr}: #{pt.send(attr)}", page: "#{attr}: #{pt.scraper.send(attr)}" }
    end
  end
end

def check_listing_data(pt)
  pt.listing_data.each do |attr, value|
    next if attr == "item_data"
    if value && pt.scraper.listing.nil?
      pt.scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: nil listing" }
    elsif value != pt.scraper.listing[attr]
      next if %w(url digest image_download_attempted seller_domain).include?(attr)
      pt.scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: #{pt.scraper.listing[attr]}" }
    end
  end
end

def check_item_data(pt)
  return unless pt.listing_data['item_data']
  pt.listing_data['item_data'].each do |attr, value|
    item_data = pt.scraper.listing['item_data'] if pt.scraper.listing
    if value && pt.scraper.listing.nil?
      pt.scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: nil listing" }
    elsif ElasticSearchObject.is_object_in_index?(attr)
      check_es_object(pt, attr, value)
    elsif value != item_data[attr]
      next if %w(description keywords image_download_attempted seller_domain).include?(attr)
      next if value.is_a?(String) && item_data[attr].is_a?(String) && (value.downcase == item_data[attr].downcase)
      pt.scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: #{item_data[attr]}" }
    end
  end
end

def check_es_object(pt, attr, value)
  pt_value = es_object_to_hash(value)
  page_value = es_object_to_hash(pt.scraper.listing['item_data'][attr])

  pt_value.each do |k, v|
    next if (v == "default") && (page_value[k] == "hard")
    unless page_value[k] == v
      pt.scrape_errors << { pt: "#{attr}.#{k}: #{v}", page: "#{attr}.#{k}: #{page_value[k]}" }
    end
  end
end

def es_object_to_hash(varray)
  vhash = {}
  varray ||= []
  varray.each do |h|
    vhash.merge!(h)
  end
  vhash
end

def print_errors(pt)
  title_hash = category1_hash = nil
  if pt.listing_data.try(:[], 'item_data')
    title_hash = es_object_to_hash(pt.listing_data['item_data']['title'])
    category1_hash = es_object_to_hash(pt.listing_data['item_data']['category1'])
  end
  puts "##################################"
  puts "ParserTest #{pt.id} has errors!"
  puts "  title:     #{title_hash["title"]}" if title_hash
  puts "  category1: #{category1_hash["category1"]} (#{category1_hash["classification_type"]})" if category1_hash
  puts "  url:       #{pt.source_url}"

  puts "### Errors:"
  pt.scrape_errors.each do |error|
    if error[:pt].is_a?(String)
      puts "  JSON: #{error[:pt][0..500]}"
    else
      puts "  JSON: #{error[:pt]}"
    end
    if error[:page].is_a?(String)
      puts "  Page: #{error[:page][0..500]}"
    else
      puts "  Page: #{error[:page]}"
    end
  end
end

def check_parser_test(pt)
  pt.scrape_errors = []
  pt.fetch_page

  return unless check_presence(pt)

  check_statuses(pt)

  if pt.listing_data.present? && pt.scraper.is_valid?
    check_listing_data(pt)
    check_item_data(pt)
  end

  print_errors(pt) if pt.scrape_errors.any?

rescue Exception => e
  puts "ERROR for [#{pt.id}]: #{e.message}"
end

def update_parser_test(pt)
  pt.fetch_page
  pt.not_found = pt.scraper.not_found?
  pt.is_valid = pt.scraper.is_valid?
  pt.classified_sold = nil
  pt.listing_data = pt.scraper.not_found? ? nil : pt.scraper.listing
  pt.save
end

desc "Check test listings for errors"
task :check_test_listings => :environment do
  ParserTest.all.each do |pt|
    puts "## Checking [#{pt.id}]"
    check_parser_test(pt)
  end
end

task :check_test_listing => :environment do
  ptid = ENV['ID'].to_i
  pt = ParserTest.find ptid
  check_parser_test(pt)
end

task :overwrite_parser_tests => :environment do
  ParserTest.all.each do |pt|
    update_parser_test(pt)
  end
end

desc "Check image urls"
task :check_image_urls => :environment do
  ParserTest.all.each do |pt|
    next unless pt.listing_data && image = pt.listing_data["item_data"]["image_source"]
    begin
      puts "Bad image url #{image} for ParserTest #{pt.id}" unless URI.parse(image).scheme
    rescue
      puts "Bad image url #{image} for ParserTest #{pt.id}"
    end
  end
end
