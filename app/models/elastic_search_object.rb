class ElasticSearchObject

  attr_reader :name, :data

  delegate :each, to: :data

  FIELDS = %w(raw scrubbed normalized autocomplete classification_type score).map(&:to_sym)

  FIELDS.each do |key|
    define_method key do
      @data[key]
    end

    define_method "#{key}=" do |value|
      validate_fields(key)
      validate_values({key => value})
      @data[key] = value
    end
  end

  def initialize(name, opts = {})
    @name = name
    validate_name
    validate_fields(opts.keys)
    validate_values(opts)
    @data = opts
    @respond_to = []
  end

  def to_index_format
    return @data[:raw] unless valid_fields
    valid_fields.map do |attr|
      if (attr == name.to_sym) && @data[:raw]
        { name => @data[:raw] }
      elsif @data[attr]
        { attr.to_s => @data[attr] }
      end
    end.compact
  end

  def digest_string
    ElasticSearchObject::FIELDS.inject("") do |result, field|
      result + "#{@data[field]}"
    end
  end

  def valid_fields
    ElasticTools::IndexMapping.index_properties[:properties][name.to_sym][:properties].keys rescue nil
  end

  def to_s
    @data[:raw]
  end

  def validate_name
    unless ElasticTools::IndexMapping.index_properties[:properties].keys.include?(name.to_sym)
      raise "Invalid object name #{name}!"
    end
  end

  def validate_fields(attrs)
    return unless valid_fields
    attrs = [attrs] unless attrs.is_a?(Array)
    attrs.each do |attr|
      next if attr == :raw
      raise "Invalid attribute #{attr} for index object #{name}!" unless valid_fields.include?(attr)
    end
  end

  def validate_values(opts)
    return unless classification_type = opts[:classification_type]
    unless %w(hard soft metadata fall_through).include?(classification_type)
      raise "Invalid classification_type #{classification_type}!"
    end
  end
end
