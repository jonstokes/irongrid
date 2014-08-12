module Stretched
  class DefinitionProxy
    def register_script(script_name, &block)
      factory = AdapterFactory.new
      if block_given?
        factory.instance_eval(&block)
      end
      AdapterScript.register(script_name, factory)
    end
  end
end
