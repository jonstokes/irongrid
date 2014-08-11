module Stretched
  class ObjectAdapter < Registration

    delegate :[], :[]=, :each, :keys, to: :data

    def initialize(opts)
      @type, @key, @data = "ObjectAdapter", opts[:key], opts[:data]
    end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end
  end
end
