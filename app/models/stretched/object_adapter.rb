module Stretched
  class ObjectAdapter < Registration

    attr_reader :schema

    delegate :validate, to: :schema

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = Schema.new(@data["schema"])
    end

    def xpath; @data["xpath"]; end

    def attribute_setters; @data["attribute_setters"]; end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "ObjectAdapter"))
    end

  end
end
