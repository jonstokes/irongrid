class ValidatorQueue < CoreModel
  include ValidatorRedisPool

  PREFIX = "validator--"

  def self.add(key, opts)
    nkey = "#{PREFIX}#{key}"
    opts = opts.symbolize_keys
    notify "### Adding validator queue key #{nkey} for url #{opts[:url]}"
    with_redis do |conn|
      conn.set nkey, opts.to_json
    end
  end

  def self.get(key)
    nkey = "#{PREFIX}#{key}"
    notify "### Finding validator queue key #{nkey}"
    return unless value = with_redis do |conn|
      conn.get nkey
    end
    JSON.parse(value)
  end
end
