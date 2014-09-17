def map_line(mappings, line)
  if line["=>"]
    key = line.split("=>").last.strip.gsub("_", " ")
    values = line.split("=>").first.split(",").map(&:strip)
  else
    key = line.strip.gsub("_", " ")
    values = nil
  end
  mappings.merge!(key => values)
end

namespace :local_index do
  task dump_mappings: :environment do
    calibers = {}
    ElasticTools::Synonyms.caliber_synonym_lines.each do |line|
      next if line[0] == "#"
      map_line(calibers, line)
    end
    File.open("#{Rails.root}/spec/fixtures/stretched/registrations/globals/mappings/calibers.yml", "w") { |f| f.puts calibers.to_yaml }

    manufacturers = {}
    ElasticTools::Synonyms.manufacturer_synonym_lines.each do |line|
      map_line(manufacturers, line)
    end
    File.open("#{Rails.root}/spec/fixtures/stretched/registrations/globals/mappings/manufacturers.yml", "w") { |f| f.puts manufacturers.to_yaml }
  end

  task refresh: :environment do
    puts "Recreating local ES index..."
    Tire.configure { logger STDOUT, :level => 'debug' }
    Listing.recreate_index
  end

  task create: :environment do
    Tire.configure { reset :url }
    Tire.configure { logger STDOUT, :level => 'debug' }
    ElasticTools::IndexMapping.generate(Listing.index_name)
    Listing.index.refresh
  end
end
