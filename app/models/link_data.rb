class LinkData
  include Retryable

  attr_reader :url

  LINK_DATA_INDEX = "link-data-index"
  LINK_DATA_KEYS = [
    :jid,
    :page_attributes,
    :page_is_valid,
    :page_not_found,
    :listing_digest,
    :listing_dupe,
    :listing_id
  ]

  LINK_DATA_KEYS.each do |key|
    define_method(key) { @data[key] } #getters
    define_method("#{key}=") { |value| @data[key] = value } #setters
    if [:page_is_valid, :page_not_found, :listing_dupe].include?(key) #status
      define_method("#{key}?") { @data[key] }
    end
  end

  def initialize(attrs)
    new_from_hash(attrs) if attrs.is_a?(Hash)
    new_from_listing(attrs) if attrs.is_a?(Listing)
  end

  def update(attrs)
    attrs.symbolize_keys!
    check_attributes(attrs)
    raise "Can't update url!" if attrs.keys.include?(:url)
    @data.merge!(attrs)
    save
  end

  def save
    with_redis do |conn|
      conn.set(@url, @data.to_json)
    end
  end

  def destroy
    with_redis do |conn|
      conn.srem(LINK_DATA_INDEX, @url)
      conn.del(@url)
    end
  end

  def to_h
    @data
  end

  def self.count
    with_redis { |conn| conn.scard(LINK_DATA_INDEX) }
  end

  class << self
    alias :size :count
    alias :length :count
  end

  def self.create(attrs)
    ld = LinkData.new(attrs)
    ld.send(:create_in_redis) ? ld : nil
  end

  def self.find(url)
    return unless url.present? && (value = with_redis { |conn| conn.get(url) })
    attrs = JSON.parse(value).merge(url: url)
    LinkData.new(attrs)
  end

  def self.delete_all
    with_redis do |conn|
      while link = conn.spop(LINK_DATA_INDEX) do
        conn.del(link)
      end
    end
  end

  private

  def create_in_redis
    with_redis do |conn|
      conn.set(@url, @data.to_json) if conn.sadd(LINK_DATA_INDEX, @url)
    end
  end

  def new_from_hash(attrs)
    attrs.symbolize_keys!
    check_attributes(attrs)
    @url = attrs[:url]
    @data = attrs.reject { |k, v| k == :url }
  end

  def new_from_listing(listing)
    @url = listing.url
    @data = {
      listing_id: listing.id,
      listing_digest: listing.digest,
    }
  end

  def check_attributes(attrs)
    attrs.keys.each { |a| raise "Invalid attribute #{a}" unless (LINK_DATA_KEYS + [:url]).include?(a) }
  end

  def with_redis(&block)
    LinkData.with_redis(&block)
  end

  def self.with_redis(&block)
    retryable(sleep: 0.5) do
      IRONGRID_REDIS_POOL.with &block
    end
  end
end
