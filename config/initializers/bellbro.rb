config_hash = YAML.load_file("#{Rails.root}/config/redis.yml")[Rails.env]
connection_hash = ThreadSafe::Cache.new

config_hash.each do |env, config|
  connection_hash[env.to_sym] = ConnectionPool.new(size: config[:pool]) do
    Redis.new(url: config[:url])
  end
end

Bellbro::Settings.configure do |config|
  config.logger = Rails.logger
  config.connection_pools = connection_hash
end