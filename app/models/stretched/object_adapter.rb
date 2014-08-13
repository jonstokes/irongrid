module Stretched
  class ObjectAdapter < Registration
    attr_reader :schema

    delegate :validate, to: :schema

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      schema_key = @data["schema"].keys.first
      @schema = Schema.new(key: schema_key, data: @data["schema"][schema_key])
    end

    def xpath; @data["xpath"]; end
    def scripts; @data["scripts"]; end
    def attribute_setters; @data["attribute"]; end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "ObjectAdapter"))
    end
  end
end
