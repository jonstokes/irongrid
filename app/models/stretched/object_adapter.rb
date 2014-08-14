module Stretched
  class ObjectAdapter < Registration
    attr_reader :schema

    delegate :validate, :validate_property, to: :schema
    delegate :key, to: :schema, prefix: true

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = Stretched::Registration.find_or_create(@data["schema"], Schema)
    end

    def xpath; @data["xpath"]; end
    def scripts; @data["scripts"]; end
    def attribute_setters; @data["attribute"]; end
    def queue_name; schema.key; end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "ObjectAdapter"))
    end

  end
end
