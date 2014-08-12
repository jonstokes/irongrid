module Stretched
  module ScriptSupport

    def registry
      @registry ||= {}
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

    def self.build(adapter_name, context = {})
      instance = {}

      factory = registry[adapter_name]
      factory.set_context(context)
      factory.attributes.each do |attribute_name, value|
        if value.is_a?(Proc)
          instance[attribute_name] = value.call(instance)
        else
          instance[attribute_name] = value
        end
      end

      instance
    end
  end
end
