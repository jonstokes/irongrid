namespace :local_index do
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
