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

    def self.find(key)
      super(type: "Script", key: key)
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
