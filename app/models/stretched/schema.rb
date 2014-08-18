module Stretched
  class Schema < Registration
    def initialize(opts)
      super(opts.merge(type: "Schema"))
    end

    def validate(attribute, value)
      attr = attribute.to_s
      return false unless properties && property = properties[attr]
      return false unless type_is_valid?(property['type'], value)
      return true unless property['enum'] && property['enum'].any?
      return property['enum'].include?(value)
    end

    def validate_property(attribute)
      return properties.include?(attribute.to_s)
    end

    def properties; @data['properties']; end

    private

    def type_is_valid?(property_type, value)
      if property_type == 'url'
        return is_valid_url?(value)
      elsif property_type == 'boolean'
        return value.is_a?(TrueClass) || value.is_a?(FalseClass)
      else
        return value.is_a?(property_type.classify.constantize)
      end
    end

    def is_valid_url?(link)
      begin
        uri = URI.parse(link)
        %w( http https ).include?(uri.scheme)
      rescue URI::BadURIError
        return false
      rescue URI::InvalidURIError
        return false
      end
    end

  end
end
