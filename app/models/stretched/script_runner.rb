module Stretched
  class ScriptRunner
    include Stretched::DocQueries

    attr_reader :attributes, :doc, :page

    def initialize
      @attributes = {}
    end

    def set_context(context)
      @doc = context[:doc] || context[:page].doc
      @page = Hashie::Mash.new(context[:page].to_hash)
      @session = context[:browser_session]
    end

    def method_missing(name, *args, &block)
      if block_given?
        attributes[name.to_s] = block
      else
        attributes[name.to_s] = args[0]
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
