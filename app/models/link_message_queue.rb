class LinkMessageQueue
  include Retryable

  attr_reader :set_name, :domain

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#linkset--#{domain}"
  end

  def push(messages)
    return 0 if messages.empty?
    if messages.is_a?(Array)
      messages = messages.select { |msg| msg.is_a?(LinkMessage) && is_valid_url?(msg.url) }.map(&:to_h)
    else
      messages = [messages.to_h]
    end
    add_keys_to_redis(messages)
  end

  def pop
    return unless url = with_redis { |conn| conn.spop(set_name) }
    data = with_redis { |conn| JSON.parse(conn.get(url)) }
    with_redis { |conn| conn.del(url) }
    LinkMessage.new(data.symbolize_keys)
  end

  def rem(links)
    return 0 unless links
    return 0 if links.is_a?(String) && links.blank?

    if links.is_a?(Array)
      return 0 if links.empty?
      links = links.uniq.select(&:present?)
    else
      links = [links]
    end

    remove_keys_from_redis(links)
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

  def all
    links.map do |link|
      LinkMessageQueue.find(link)
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

  #
  # This is cheating on the queue abstraction, but it
  # makes specs and pruning links easier
  #
  def self.find(link)
    return unless link.present? && (value = with_redis { |conn| conn.get(link) })
    LinkMessage.new(JSON.parse(value))
  end

  private

  def links
    with_redis do |conn|
      conn.smembers(set_name)
    end
  end

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
