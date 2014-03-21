class ImageSet < LinkSet
  attr_reader :domain, :set_name

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#imageset--#{domain}"
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

  private

  def is_valid_url?(key)
    !!URI.parse(key).host rescue nil
  end
end
