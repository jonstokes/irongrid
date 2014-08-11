module Stretched
  class RateLimit < Registration
    def initialize(opts)
      @type, @key, @data = "RateLimit", opts[:key], opts[:data]
    end

    def self.find(key)
      super(type: "RateLimit", key: key)
    end
  end
end
