module Stretched
  class DefinitionProxy
    def attributes_for_adapter(adapter_name, &block)
      factory = AdapterFactory.new
      if block_given?
        factory.instance_eval(&block)
      end
      ObjectAdapter.registry[adapter_name] = factory
    end
  end
end
