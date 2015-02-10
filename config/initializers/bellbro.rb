config_hash = YAML.load_file("#{Rails.root}/config/redis.yml")[Rails.env]
connection_hash = ThreadSafe::Cache.new

config_hash.each do |pool, config|
  puts "## Initializing redis pool #{pool} with size #{config['pool']} and url #{config['url']}"
  connection_hash[pool.to_sym] = ConnectionPool.new(size: config['pool']) do
    Redis.new(url: config['url'])
  end
end

Bellbro::Settings.configure do |config|
  config.logger = Rails.logger
  config.connection_pools = connection_hash
end