module Stretched
  class Schema < Registration
    def initialize(opts)
      super(opts.merge(type: "Schema"))
    end

    def validate(attribute, value)
      #stuff
    end

    def self.find(key)
      super(type: "Schema", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "Schema"))
    end

    def validate_node(node, value)
      #stuff
    end

  end
end
