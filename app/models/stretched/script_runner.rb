module Stretched
  class ScriptRunner
    include DocQueries

    attr_reader :attributes, :doc, :context

    def initialize
      @attributes = {}
    end

    def set_context(context)
      @context = context
      @doc = context[:doc] || context[:page].try(:doc)
    end

    def method_missing(name, *args, &block)
      if block_given?
        attributes[name.to_sym] = block
      else
        attributes[name.to_sym] = args[0]
      end
    end
  end
end
