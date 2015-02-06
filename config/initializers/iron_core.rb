def pool_size
  size = Figaro.env.redis_pool.to_i
  size.zero? ? 5 : size
rescue
  10
end

IronCore::Settings.configure do |config|
  config.irongrid_redis_pool = ConnectionPool.new(timeout: 5, size: pool_size) do
    Redis.new(url: Figaro.env.irongrid_redis_url)
  end

  config.validator_redis_pool = ConnectionPool.new(timeout: 5, size: pool_size) do
    Redis.new(url: Figaro.env.validator_redis_url)
  end

  config.ironsights_redis_pool = ConnectionPool.new(timeout: 5, size: pool_size) do
    Redis.new(url: Figaro.env.ironsights_redis_url)
  end
end
