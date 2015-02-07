def pool_size
  size = Figaro.env.redis_pool.to_i
  size.zero? ? 5 : size
rescue
  10
end

irongrid = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.irongrid_redis_pool)
end

validator = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.validator_redis_pool)
end

ironsights = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.ironsights_redis_pool)
end

IronCore::Settings.configure do |config|
  config.connection_pools = {
      irongrid_redis_pool:   irongrid,
      validator_redis_pool:  validator,
      ironsights_redis_pool: ironsights
  }
  config.logger = Rails.logger
end
