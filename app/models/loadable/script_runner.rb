module Loadable
  class ScriptRunner

    attr_reader :actions
    attr_accessor :context

    def initialize
      @actions = {}
    end

    def with_context(new_context)
      @context = new_context
      yield
      @context = nil
    end
    
    def method_missing(name, *args, &block)
      if block_given?
        actions[name.to_s] = block
      else
        actions[name.to_s] = args[0]
      end
    rescue RuntimeError => e
      if !!e.message[/add a new key into hash during iteration/]
        super
      else
        raise e
      end
    end
  end
end
