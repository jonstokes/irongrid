module Stretched
  class Registration
    include Retryable
    include StretchedRedisPool

    attr_accessor :registration_type, :key, :data

    def initialize(opts)
      opts.symbolize_keys!
      @registration_type, @key = opts[:type], opts[:key]
      opts_data = opts[:data] || {}
      if @keyref = opts[:$key]
        @data = self.class.find(
          type: registration_type,
          key: @keyref
        ).data.merge(opts_data)
      else
        @data = opts_data
      end
    end

    def save
      with_redis do |conn|
        conn.sadd "registrations", "#{registration_type}::#{key}"
        conn.set "registrations::#{registration_type}::#{key}", data.to_json
      end
    end

    def destroy
      with_redis do |conn|
        conn.srem "registrations", "#{registration_type}::#{key}"
        conn.del "registrations::#{registration_type}::#{key}"
      end
    end

    def self.create(opts)
      registration = Registration.new(opts)
      registration.save
      registration
    end

    def self.find(opts)
      opts.symbolize_keys!
      data = with_redis do |conn|
        conn.get "registrations::#{opts[:type]}::#{opts[:key]}"
      end
      if data
        self.new(opts.merge(data: JSON.parse(data)))
      else
        raise "No such #{opts[:type]} registration with key #{opts[:key]}!"
      end
    end
  end
end
