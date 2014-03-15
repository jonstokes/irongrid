class ListingSet < LinkSet
  attr_reader :set_name

  def initialize
    @set_name = "listingset"
  end

  def add(keys)
    return 0 unless keys
    return 0 if keys.is_a?(String) && keys.blank?

    if keys.is_a?(Array)
      return 0 if keys.empty?
      keys = keys.uniq.map(&:to_json)
    else
      keys = [keys]
    end

    redis_pool.with { |conn| conn.sadd(set_name, keys) }
    keys.count
  end

  def pop
    redis_pool.with do |conn|
      return unless conn.exists(set_name)
      JSON.parse(conn.spop(set_name)).symbolize_keys rescue nil
    end
  end
end
