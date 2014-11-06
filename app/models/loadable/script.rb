module Loadable
  class Script
    include Retryable
    include IrongridRedisPool

    attr_accessor :key, :data

    TABLE = "site-scripts"

    def initialize(opts)
      opts.symbolize_keys!
      @key, @data = opts[:key], opts[:data]
    end

    def save
      self.class.write_to_redis(
        key: key,
        data: data
      )
    end

    def destroy
      self.class.unregister(key)
    end

    def register
      # NOTE: This returns a populated instance of ScriptRunner
      # that has all extensions defined on it and contains
      # Procs for the code defined in @data
      eval data
    end

    def self.runner(key = nil)
      return Loadable::ScriptRunner.new unless key
      script = find(key)
      script.register
    end

    def self.load_file(filename)
      source = get_source(filename)
      key = source[/(script)\s+\".*?\"/].split(/(script) \"/).last.split(/\"/).last
      [Hashie::Mash.new(key: key, type: "Script" , data: source)]
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

    def self.count
      with_redis do |conn|
        conn.scard TABLE
      end
    end

    def self.write_to_redis(reg_hash)
      key, registration_type, data = reg_hash[:key], reg_hash[:type], reg_hash[:data]
      with_redis do |conn|
        conn.sadd "#{TABLE}", "#{key}"
        conn.set "#{TABLE}::#{key}", write_redis_format(data)
      end
    end

    def self.write_redis_format(data)
      data.to_yaml
    end

    def self.keys
      with_redis do |conn|
        conn.smembers "#{TABLE}"
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
        conn.srem "#{TABLE}", "#{key}"
        conn.del "#{TABLE}::#{key}"
      end
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

    def self.find(key)
      data = with_redis do |conn|
        conn.get "#{TABLE}::#{key}"
      end

      if data
        self.new(key: key, data: read_redis_format(data))
      else
        raise "No such script with key #{key}!"
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
