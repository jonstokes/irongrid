module Stretched
  class ObjectAdapter < Registration

    attr_reader :attribute_setters, :schema, :xpath

    delegate :validate, to: :schema

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = Schema.new(@data["schema"])
      @xpath = @data["xpath"]
      @attribute_setters = @data["attribute"]
    end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "ObjectAdapter"))
    end

  end
end
