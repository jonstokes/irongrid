module Stretched
  class ObjectAdapter < Registration

    def initialize(opts)
      super(opts.merge(type: "ObjectAdapter"))
      @schema = Schema.new(@data["schema"])
      @xpath = @data["xpath"]
      @attribute_setters = @data["attribute"]
    end

    def self.find(key)
      super(type: "ObjectAdapter", key: key)
    end
  end
end
