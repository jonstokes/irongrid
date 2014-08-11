module Stretched
  class Schema < Registration
    def initialize(opts)
      super(opts.merge(type: "Schema"))
    end

    def validate(attribute, value)
      attr = attribute.to_s
      return false unless property = @data['properties'][attr]
      return false unless type_is_valid?(property['type'], value)
      return true unless property['enum'] && property['enum'].any?
      return property['enum'].include?(value)
    end

    def self.find(key)
      super(type: "Schema", key: key)
    end

    def self.create(opts)
      super(opts.merge(type: "Schema"))
    end

    private

    def type_is_valid?(property_type, value)
      unless property_type == 'url'
        return value.is_a?(property_type.classify.constantize)
      else
        return is_valid_url?(value)
      end
    end

    def is_valid_url?(str)
      !!URI.parse(str).scheme rescue false
    end
  end
end
