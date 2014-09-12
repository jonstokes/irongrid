class DefinitionProxy
  def script(script_name, &block)
    runner = ScriptRunner.new

    # Set up runner instance for use
    if block_given?
      runner.instance_eval(&block)
    end

    runner
  end
end
