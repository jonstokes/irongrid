class Registration
  include StretchedRedisPool

  attr_accessor :type, :key, :data

  def initialize(opts)
    @type, @key, @data = opts[:type], opts[:key], opts[:data]
  end

  def save
    with_redis do |conn|
      conn.sadd "registrations", "#{type}::#{key}"
      conn.set "#{registrations}::#{type}::#{key}", data
    end
  end

  def destroy
    with_redis do |conn|
      conn.srem "registrations", "#{type}::#{key}"
      conn.del "#{registrations}::#{type}::#{key}"
    end
  end

  def self.create(opts)
    Registration.new(opts).save
  end
end
