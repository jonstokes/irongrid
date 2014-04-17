module IrongridRedisPool
  def self.included(klass)
    klass.extend(self)
  end

  def with_redis(&block)
    retryable(sleep: 0.5) do
      IRONGRID_REDIS_POOL.with &block
    end
  end
end
