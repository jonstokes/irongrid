module Stretched
  class ObjectAdapter < Registration
    attr_reader :schema

    delegate :validate, :validate_property, to: :schema
    delegate :key, to: :schema, prefix: true

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = Stretched::Schema.find_or_create(@data["schema"])
    end

    def xpath; @data["xpath"]; end
    def scripts; @data["scripts"]; end
    def attribute_setters; @data["attribute"]; end
    def queue_name; @data['queue'] ; end

  end
end
