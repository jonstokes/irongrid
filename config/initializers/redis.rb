def pool_size
  size = Figaro.env.redis_pool.to_i
  size.zero? ? 5 : size
rescue
  10
end

IRONGRID_REDIS_POOL   = ConnectionPool.new(timeout: 5, size: pool_size) { Redis.new(url: Figaro.env.irongrid_redis_url) }
IRONSIGHTS_REDIS_POOL = ConnectionPool.new(timeout: 5, size: pool_size) { Redis.new(url: Figaro.env.ironsights_redis_url) }
VALIDATOR_REDIS_POOL  = ConnectionPool.new(timeout: 5, size: pool_size) { Redis.new(url: Figaro.env.validator_redis_url) }
