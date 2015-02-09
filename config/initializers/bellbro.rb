def pool_size
  size = Figaro.env.redis_pool.to_i
  size.zero? ? 10 : size
end

connection_hash = ThreadSafe::Cache.new
connection_hash[:stretched_redis_pool] = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.stretched_redis_url)
end
connection_hash[:irongrid_redis_pool] = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.irongrid_redis_url)
end
connection_hash[:validator_redis_pool] = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.validator_redis_url)
end
connection_hash[:ironsights_redis_pool] = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.ironsights_redis_url)
end

Bellbro::Settings.configure do |config|
  config.logger = Rails.logger
  config.connection_pools = connection_hash
end