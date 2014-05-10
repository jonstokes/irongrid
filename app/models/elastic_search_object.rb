class ElasticSearchObject

  attr_reader :name

  FIELDS = %w(raw scrubbed normalized classification_type score).map(&:to_sym)

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

  def to_a
    @data.map do |k, v|
      if k == :raw
        { name => v }
      else
        { k.to_s => v }
      end
    end
  end

  def to_s
    @data[:raw]
  end
end
