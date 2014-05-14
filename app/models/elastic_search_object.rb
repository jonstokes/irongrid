class ElasticSearchObject

  attr_reader :name

  FIELDS = %w(raw scrubbed normalized autocomplete classification_type score).map(&:to_sym)

  FIELDS.each do |key|
    define_method key do
      @data[key]
    end

    define_method "#{key}=" do |value|
      @data[key] = value
    end
  end

  def initialize(name, opts = {})
    @name = name
    @data = opts
    @respond_to = []
  end

  def to_index_format
    attrs = ElasticTools::IndexMapping.index_properties[:properties][name.to_sym][:properties].keys rescue nil
    return @data[:raw] unless attrs
    attrs.map do |attr|
      if attr == name.to_sym
        { name => @data[:raw] }
      else
        { attr.to_s => @data[attr] }
      end
    end
  end

  def digest_string
    ElasticSearchObject::FIELDS.inject("") do |result, field|
      result + "#{@data[field]}"
    end
  end

  def to_s
    @data[:raw]
  end
end
