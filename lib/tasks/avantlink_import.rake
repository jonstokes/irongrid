def generate_file_sources(xml)
  product_count = 0
  files = []
  file_header = "<xml>\n<Products>"
  file_footer = "</Products>\n</xml>"
  file_text = file_header.dup

  xml.each_line do |line|
    file_text << line
    product_count += 1 if line["</Product>"]
    if (product_count % 1000).zero?
      file_text << file_footer
      files << file_text
      file_text = file_header.dup
    end
  end
  files
end

def write_files(files)
  files.each_with_index do |file, i|
    File.open("tmp/export-#{i}.xml", "w") do |f|
      f.puts file
    end
  end
end

task :write_from_local => :environment do

  # Break up large import file and write it out to smaller files
  xml = File.open("tmp/import.xml") { |f| f.read }
  files = generate_files_sources(xml)
  write_files(files)

  # Side-load the smaller files into the site model's feeds list
  site = IronCore::Site.new(domain: "www.blueridgefirearms.com")
  site.feeds = []
  files.each_with_index do |f, i|
    site.feeds << Feed.new(filename: "tmp/export-#{i}.xml")
  end

  # Run the side-loaded feeds and populate the db
  ProductFeedWorker.new.perform(site: site, domain: site.domain)
end

