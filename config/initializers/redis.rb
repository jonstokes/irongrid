pool_size = Figaro.env.redis_pool.to_i rescue 10
IRONGRID_REDIS_POOL = ConnectionPool.new(timeout: 5, size: pool_size) { Redis.new(url: Figaro.env.irongrid_redis_url) }

