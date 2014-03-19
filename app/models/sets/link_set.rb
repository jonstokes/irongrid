class LinkSet
  attr_reader :set_name, :domain

  def self.connect!
    pool_size = Figaro.env.redis_pool_size rescue 10
    @@pool = ConnectionPool.new(timeout: 5, size: pool_size) { Redis.new(url: Figaro.env.irongrid_redis_url) }
  end

  def self.redis_pool
    @@pool
  end

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#linkset--#{domain}"
  end

  def add(keys)
    return 0 unless keys
    return 0 if keys.is_a?(String) && keys.blank?

    if keys.is_a?(Array)
      return 0 if keys.empty?
      keys = keys.uniq.select { |key| !key.empty? && is_valid_url?(key) }
    else
      keys = [keys]
    end


    redis_pool.with { |conn| conn.sadd(set_name, keys) }
    keys.count
  end

  def pop
    redis_pool.with do |conn|
      return unless conn.exists(set_name)
      conn.spop(set_name)
    end
  end

  def clear
    redis_pool.with do |conn|
      conn.del(set_name)
    end
  end

  def empty?
    redis_pool.with do |conn|
      return true unless conn.exists(set_name)
      conn.scard(set_name) == 0
    end
  end

  def has_key?(key)
    redis_pool.with do |conn|
      return false unless key.present? && conn.exists(set_name)
      return true if conn.sismember(set_name, key)
    end
  end

  def size
    redis_pool.with do |conn|
      return 0 unless conn.exists(set_name)
      conn.scard(set_name)
    end
  end

  alias length size
  alias count size

  private

  def is_valid_url?(key)
    return unless host = URI.parse(key).host rescue nil
    !!@domain[host.sub("www.", "")]
  end

  def redis_pool
    LinkSet.redis_pool
  end
end
