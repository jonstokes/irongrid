module Stretched
  class Registration
    include Retryable
    include StretchedRedisPool

    attr_accessor :registration_type, :key, :data

    def initialize(opts)
      @registration_type, @key = opts[:type], opts[:key]
      if @keyref = opts["$key"]
        @data = self.class.find(@keyref).data.merge(opts[:data])
      else
        @data = {}
      end
    end

    def save
      with_redis do |conn|
        conn.sadd "registrations", "#{registration_type}::#{key}"
        conn.set "#{registrations}::#{registration_type}::#{key}", data
      end
    end

    def destroy
      with_redis do |conn|
        conn.srem "registrations", "#{registration_type}::#{key}"
        conn.del "registrations::#{registration_type}::#{key}"
      end
    end

    def self.create(opts)
      Registration.new(opts).save
    end

    def self.find(opts)
      data = with_redis do |conn|
        conn.get "registrations::#{opts[:type]}::#{opts[:key]}"
      end
      if data
        self.new(opts.merge(data: data))
      else
        raise "No such #{opts[:type]} registration with key #{opts[:key]}!"
      end
    end
  end
end
