module Stretched
  class Registration
    include Retryable
    include StretchedRedisPool

    attr_accessor :registration_type, :key, :data

    TYPES = %w(schema script object_adapter session_definition rate_limit)

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

    def self.count
      with_redis do |conn|
        conn.scard "registrations"
      end

    end

    def self.load_file(filename)
      source = get_source(filename)
      source.keys.select { |k| TYPES.include?(k.to_s) }.map do |type|
        source[type].map do |key, registration|
          class_name = type.classify
          "Stretched::#{class_name}".constantize.new(key: key.to_s, type: class_name, data: registration)
        end
      end.flatten
    end

    def self.create_from_file(filename)
      load_file(filename).map do |registration|
        registration.save
        registration
      end
    end

    def self.create(opts)
      registration = new(opts)
      registration.save
      registration
    end

    def self.find(opts)
      opts.symbolize_keys!
      type, key = opts[:type], opts[:key]
      data = with_redis do |conn|
        conn.get "registrations::#{type}::#{key}"
      end
      if data
        self.new(opts.merge(data: JSON.parse(data)))
      else
        raise "No such #{type} registration with key #{key}!"
      end
    end

    def self.get_source(filename)
      format = File.extname(filename).split(".").last.to_sym
      if format == :rb
        File.open(filename) { |f| f.read }
      else
        YAML.load_file(filename)
      end
    end

  end
end
