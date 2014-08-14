module Stretched
  class Session
    def initialize(opts)
      @queue = opts[:queue]
      @session_definition = get_registration(opts[:session_definition], SessionDefinition)
      @object_adapters = opts[:object_adapters].map { |obj| get_registration(obj, ObjectAdapter) }
      @urls = opts[:urls]
    end

    def get_registration(obj, klass)
      return klass.find(obj) if obj.is_a?(String)
      key = obj.keys.first
      @schema = klass.create(key: key, data: obj[key])
    end
  end
end
