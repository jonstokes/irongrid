class LinkSet
  attr_reader :set_name, :domain

  def self.redis_pool
    IRONGRID_REDIS_POOL
  end

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#linkset--#{domain}"
  end

  def push(keys)
    keys = [keys] unless keys.is_a?(Array)
    keys.compact!
    return 0 if keys.empty?

    urls = keys.map { |k| k[:url] if k[:url] && is_valid_url?(k[:url]) }.compact.uniq

    redis_pool.with do |conn|
      conn.sadd(set_name, urls)
      keys.select { |k| k[:id] }.each do |key|
        key_json = key.reject { |k| k == :url }.to_json
        conn.set key[:url], key_json
      end
    end
    urls.count
  end

  def pop
    redis_pool.with do |conn|
      return unless conn.exists(set_name)
      url = conn.spop(set_name)
      hash_json = conn.get(url)
      return { url: url } unless hash_json
      hash = JSON.parse(hash_json)
      { url: url, id: hash["id"].to_i, digest: hash["digest"] }
    end
  end

  def empty?
    redis_pool.with do |conn|
      return true unless conn.exists(set_name)
      conn.scard(set_name) == 0
    end
  end

  def clear
    redis_pool.with do |conn|
      urls = conn.smembers(set_name)
      urls.each { |url| conn.del(url) }
      conn.del(set_name)
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

  alias add push
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
