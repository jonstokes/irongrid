module Stretched
  class DefinitionProxy
    def script(script_name, &block)
      runner = ScriptRunner.new
      Extension.register_all

      # Define all extensions on the runner instance
      Extension.registry.each_pair do |extname, block|
        runner.instance_eval(&block)
      end

      # Set up runner instance for later use
      if block_given?
        runner.instance_eval(&block)
      end

      # Register runner instance in global registry
      Script.register(script_name, runner)
    end

    def extension(script_name, &block)
      Extension.register(script_name, &block)
    end

  end
end
