def should_destroy?(pt)
  (pt.scraper && pt.scraper[:error]) || (pt.listing_data.present? && !pt.html_on_s3.present?)
end

desc "Check test listings for errors"
task :check_test_listings => :environment do
  ParserTest.all.each do |pt|
    puts "## Checking [#{pt.id}]"
    pt.check_parser_test
  end
end

task :check_test_listing => :environment do
  ptid = ENV['ID'].to_i
  pt = ParserTest.find ptid
  pt.check_parser_test
end

task :overwrite_parser_tests => :environment do
  ParserTest.all.each do |pt|
    pt.fetch_page
    if should_destroy?(pt)
      puts "# Destroying #{pt.id}"
      pt.destroy
    else
      puts "# Updating #{pt.id}"
      pt.update_listing_data!
    end
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
