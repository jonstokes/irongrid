module Stretched
  class Script < Registration

    def initialize(opts)
      super(opts.merge(type: "Script"))
    end

    def register_runner
      eval data
    end

    def self.runner(key)
      script = find(key)
      script.register_runner
      registry[script.key]
    end

    def save
      with_redis do |conn|
        conn.sadd "registrations", "#{registration_type}::#{key}"
        conn.set "registrations::#{registration_type}::#{key}", data
      end
    end

    def self.find(key)
      data = with_redis do |conn|
        conn.get "registrations::Script::#{key}"
      end
      if data
        self.new(data: data)
      else
        raise "No such Script registration with key #{key}!"
      end
    end

    def self.create(opts)
      super(opts.merge(type: "Script"))
    end

    def self.registry
      @registry ||= {}
    end

    def self.register(script_name, runner)
      @registry ||= {}
      @register[script_name] = runner
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

  end
end
