class ImageQueue < LinkMessageQueue
  include IrongridRedisPool

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

  def clear
    with_redis do |conn|
      conn.del(set_name)
    end
  end

  alias add push

  private

  def remove_keys_from_redis(keys)
    with_redis { |conn| conn.srem(set_name, keys) }
    keys.count
  end

  def is_valid_url?(key)
    !!URI.parse(key).host rescue false
  end
end
