module Stretched
  class Registration
    include Stretched::Retryable
    include StretchedRedisPool

    attr_accessor :registration_type, :key, :data

    TYPES = %w(schema script object_adapter session_definition rate_limit)

    def initialize(opts)
      opts.symbolize_keys!
      @registration_type, @key = opts[:type], opts[:key]
      opts_data = opts[:data] || {}
      if @keyref = opts_data['$key']
        @data = self.class.find(
          type: registration_type,
          key: @keyref
        ).data.merge(opts_data.reject { |k, v| k == "$key" })
      else
        @data = opts_data
      end
    end

    def save
      self.class.write_to_redis(
        type: registration_type,
        key: key,
        data: data
      )
    end

    def destroy
      self.class.unregister(type: registration_type, key: key)
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
          Hashie::Mash.new(key: key.to_s, type: class_name, data: registration)
        end
      end.flatten
    end

    def self.write_to_redis(reg_hash)
      key, registration_type, data = reg_hash[:key], reg_hash[:type], reg_hash[:data]
      validate_against_schema(data)
      with_redis do |conn|
        conn.sadd "registrations", "#{registration_type}::#{key}"
        conn.set "registrations::#{registration_type}::#{key}", write_redis_format(data)
      end
    end

    def self.write_redis_format(data)
      data.to_yaml
    end

    def self.keys
      with_redis do |conn|
        conn.smembers "registrations"
      end.select do |key|
        registration_type = self.name.split("::").last
        !!key["#{registration_type}::"]
      end.map do |key|
        key.split("::").last
      end
    end

    def self.read_redis_format(data)
      YAML.load(data)
    end

    def self.unregister(reg_hash)
      key, registration_type = reg_hash[:key], reg_hash[:type]
      with_redis do |conn|
        conn.srem "registrations", "#{registration_type}::#{key}"
        conn.del "registrations::#{registration_type}::#{key}"
      end
    end

    def self.register_from_file(filename)
      load_file(filename).map do |reg_hash|
        write_to_redis(reg_hash)
      end
    end

    def self.validate_against_schema(data)
      # FIXME:
      true
    end

    def self.create_from_file(filename)
      load_file(filename).map do |reg_hash|
        create(reg_hash)
      end
    end

    def self.create(opts)
      registration = new(opts)
      registration.save
      registration
    end

    def self.find_or_create(arg)
      return unless arg
      return find(arg) if arg.is_a?(String)
      key = arg.keys.first
      create(key: key, data: arg[key])
    end

    def self.find(opts)
      opts = convert_find_opts(opts)
      type, key = opts[:type], opts[:key]

      data = with_redis do |conn|
        conn.get "registrations::#{type}::#{key}"
      end

      if data
        self.new(opts.merge(data: read_redis_format(data)))
      else
        raise "No such #{type} registration with key #{key}!"
      end
    end

    def self.convert_find_opts(opts)
      if opts.is_a?(String)
        type = self.name.split("::").last
        opts = { type: type, key: opts }
      end
      opts.symbolize_keys!
      opts
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
