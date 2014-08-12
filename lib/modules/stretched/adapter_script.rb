module Stretched
  module AdapterScript
    # Script support
    #

    def self.registry
      @registry ||= {}
    end

    def self.register(script_name, factory)
      @registry ||= {}
      @register[script_name] = factory
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

  end
end
