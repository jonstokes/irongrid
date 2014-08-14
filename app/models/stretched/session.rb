module Stretched
  class Session
    def initialize(opts)
      @queue = opts[:queue]
      @session_definition = Stretched::Registration.find_or_create(opts[:session_definition], SessionDefinition)
      @object_adapters = opts[:object_adapters].map do |obj|
        Stretched::Registration.find_or_create(obj, ObjectAdapter)
      end
      @urls = opts[:urls]
    end
  end
end
