Tire.configure { logger 'log/elasticsearch.log', :level => 'debug' }

namespace :tire do
  namespace :index do
    desc "Create Elasticsearch index with mappings"
    task rebuild: :environment do
      index_name = ENV['LISTINGS_INDEX']
      raise "Error: You must specify LISTINGS_INDEX!" unless index_name
      index = Tire::Index.new index_name
      index.delete if index.exists?
      ElasticTools::IndexMapping.generate(index_name)
    end

    desc "Seed index with all listings"
    task seed: :environment do
      puts "Rebuilding index..."
      Rake::Task['tire:index:rebuild'].execute
      puts "Index rebuilt!"
      batch_total = 0
      batch_count = 0
      Listing.where(:inactive => [nil, false]).where("item_data->>'availability' = 'in_stock'").find_in_batches(:batch_size => 100) do |batch|
        puts "Importing listing batch starting at id #{batch.first.id}..."
        start_time = Time.now
        Listing.index.import batch
        total_time = Time.now - start_time
        puts "Batch #{batch_count += 1} done in #{total_time} seconds. #{batch_total += batch.size} active listings indexed."
      end
    end
  end
end
