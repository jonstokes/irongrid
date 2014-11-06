module ObjectMapper
  def transform(opts)
    json, listing, mapping = opts[:source], opts[:destination], opts[:mapping]
    mapping.each do |key, value|
      if value.is_a?(Hashie::Mash)
        field = Hashie::Mash.new
        nopts = {
            source: json,
            destination: field,
            mapping: value
        }
        transform(nopts)
        listing[key] = field unless field.empty?
      else
        next unless json[value]
        listing[key] = json[value]
      end
    end
  end

  def reverse_map(opts)
    source, value = opts[:source], opts[:value]
    source.each do |k, v|
      if v.is_a?(Hashie::Mash)
        reverse_map(source: v,value: value)
      else
        return v if v == value
      end
    end
  end
end
