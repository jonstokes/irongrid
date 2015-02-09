def pool_size
  size = Figaro.env.redis_pool.to_i
  size.zero? ? 10 : size
end

stretched = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Figaro.env.stretched_redis_pool)
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

Bellbro::Settings.configure do |config|
  config.logger = Rails.logger
  config.connection_pools = {
      irongrid_redis_pool:   irongrid,
      validator_redis_pool:  validator,
      ironsights_redis_pool: ironsights,
      stretched_redis_pool:  stretched
  }
end