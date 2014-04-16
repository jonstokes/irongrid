class LinkQueue
  include Retryable

  attr_reader :set_name, :domain

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#linkset--#{domain}"
  end

  def push(keys)
    return 0 if keys.empty?
    if keys.is_a?(Array)
      keys = keys.uniq.select { |key| !key.empty? && key[:url] && is_valid_url?(key[:url]) }
    else
      keys = [keys]
    end
    add_keys_to_redis(keys)
  end

  def pop
    return unless url = with_redis { |conn| conn.spop(set_name) }
    data = with_redis { |conn| JSON.parse(conn.get(url)) }
    with_redis { |conn| conn.del(url) }
    data.symbolize_keys
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

    remove_keys_from_redis(keys)
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


  def self.find(url)
    # This makes specs easier
    return unless url.present? && (value = with_redis { |conn| conn.get(url) })
    JSON.parse(value)
  end

  private

  def add_keys_to_redis(keys)
    count = 0
    keys.each do |key|
      with_redis do |conn|
        if conn.sadd(set_name, key[:url])
          conn.set(key[:url], key.to_json)
          count += 1
        end
      end
    end
    count
  end

  def remove_keys_from_redis(keys)
    keys.each do |key|
      with_redis do |conn|
        conn.srem(set_name, key)
        conn.del(key)
      end
    end
    keys.count
  end

  def is_valid_url?(key)
    return unless host = URI.parse(key).host rescue false
    !!@domain[host.sub("www.", "")]
  end

  def with_redis(&block)
    retryable(sleep: 0.5) do
      IRONGRID_REDIS_POOL.with &block
    end
  end

  def self.with_redis(&block)
    retryable(sleep: 0.5) do
      IRONGRID_REDIS_POOL.with &block
    end
  end
end
