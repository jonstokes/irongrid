module Stretched
  class ScriptRunner
    include Stretched::DocQueries

    attr_reader :attributes, :doc, :page

    def initialize
      @attributes = {}
    end

    def set_context(context)
      @doc = context[:doc] || context[:page].try(:doc)
      @page = Hashie::Mash.new(context[:page].try(:to_h))
    end

    def method_missing(name, *args, &block)
      if block_given?
        attributes[name.to_s] = block
      else
        attributes[name.to_s] = args[0]
      end
    end
  end
end
