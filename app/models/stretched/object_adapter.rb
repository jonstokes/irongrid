module Stretched
  class ObjectAdapter < Registration
    attr_reader :schema

    delegate :validate, :validate_property, to: :schema
    delegate :key, to: :schema, prefix: true

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = get_schema
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

    private

    def get_schema
      return Schema.find(@data["schema"]) if @data["schema"].is_a?(String)
      schema_key = @data["schema"].keys.first
      @schema = Schema.create(key: schema_key, data: @data["schema"][schema_key])
    end
  end
end
