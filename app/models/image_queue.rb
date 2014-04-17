class ImageQueue < LinkMessageQueue
  include IrongridRedisPool

  attr_reader :domain, :set_name

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#imageset--#{domain}"
  end

  def push(keys)
    return 0 unless keys
    return 0 if keys.is_a?(String) && keys.blank?

    if keys.is_a?(Array)
      return 0 if keys.empty?
      keys = keys.uniq.select { |key| !key.empty? && is_valid_url?(key) }
    end

    with_redis { |conn| conn.sadd(set_name, keys) }
  end

  def pop
    with_redis do |conn|
      return unless conn.exists(set_name)
      conn.spop(set_name)
    end
  end

  def rem(keys)
    return 0 unless keys
    return 0 if keys.is_a?(String) && keys.blank?

    if keys.is_a?(Array)
      return 0 if keys.empty?
      keys = keys.uniq.select { |key| !key.empty? }
    else
      keys = [keys]
    end

    with_redis { |conn| conn.srem(set_name, keys) }
    keys.count
  end

  def clear
    with_redis do |conn|
      conn.del(set_name)
    end
  end

  def empty?
    with_redis do |conn|
      return true unless conn.exists(set_name)
      conn.scard(set_name) == 0
    end
  end

  def members
    with_redis do |conn|
      conn.smembers(set_name)
    end
  end

  def any?
    !empty?
  end

  def has_key?(key)
    with_redis do |conn|
      return false unless key.present? && conn.exists(set_name)
      return true if conn.sismember(set_name, key)
    end
  end

  def size
    with_redis do |conn|
      return 0 unless conn.exists(set_name)
      conn.scard(set_name)
    end
  end

  alias add push
  alias length size
  alias count size

  private

  def is_valid_url?(key)
    !!URI.parse(key).host rescue false
  end
end
