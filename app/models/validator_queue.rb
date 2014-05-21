class ValidatorQueue < CoreModel
  include ValidatorRedisPool

  PREFIX = "validator--"

  def self.add(opts)
    opts = opts.symbolize_keys
    key = "#{PREFIX}#{Digest::MD5.hexdigest(opts[:url])}"
    Rails.logger.info "### Adding validator queue key #{key} for url #{opts[:url]}"
    with_redis do |conn|
      conn.set key, opts.to_json
    end
  end

  def self.get(key)
    nkey = "#{PREFIX}#{key}"
    Rails.logger.info "### Finding validator queue key #{key}"
    return unless value = with_redis do |conn|
      conn.get nkey
    end
    with_redis { |conn| conn.del nkey }
    JSON.parse(value)
  end
end
